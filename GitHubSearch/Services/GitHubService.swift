//
//  GitHubService.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RealmSwift
import Firebase
import RxSwift
import RxRealm
import RxFirebase
import Moya

class GitHubService {
    struct Constants {
        static let providerID: String = "github.com"
    }
    
    private var apiProvider: MoyaProvider<GitHubMoyaService>
    private var oauthProvider: OAuthProvider
    private var realm: Realm
    
    private var disposeBag = DisposeBag()
    
    public init() throws {
        apiProvider = MoyaProvider<GitHubMoyaService>()
        oauthProvider = OAuthProvider(providerID: Constants.providerID)
        realm = try Realm()
    }
    
    // MARK: - Authentication
    public func getCurrentUser() -> UserModel? {
        realm.objects(UserModel.self).first
    }
    
    // MARK: Sign In
    enum SignInError: Error {
        case dismissed
        case undefined
    }
    
    public func signIn() -> Single<UserModel> {
        oauthProvider.rx
            .getCredentialWith(nil, skipError: true)
            .flatMap(signIn(with:))
            .map(parseUserModel(from:))
            .do(onSuccess: saveUser(_:))
    }
    
    private func signIn(with credential: AuthCredential) -> Single<AuthDataResult> {
        Auth.auth().rx
            .signInAndRetrieveData(with: credential)
            .asSingle()
    }
    
    private func parseUserModel(from authResult: AuthDataResult) throws -> UserModel {
        guard let profile = authResult.additionalUserInfo?.profile,
            let username = profile["login"] as? String,
            let bio = profile["bio"] as? String,
            let avatarUrl = profile["avatar_url"] as? String,
            let credentials = authResult.credential as? OAuthCredential,
            let token = credentials.accessToken
        else { throw SignInError.undefined }
        
        return UserModel(
            username: username,
            bio: bio,
            profilePictureUrl: avatarUrl,
            token: token)
    }
    
    private func saveUser(_ user: UserModel) {
        try? self.realm.write {
            self.realm.add(user)
        }
    }
    
    // MARK: Sign Out
    enum SignOutError: Error {
        case notLoggedIn
        case undefined
    }
    
    public func signOut() -> Result<Void, SignOutError> {
        guard let currentUser = getCurrentUser() else {
            return .failure(.notLoggedIn)
        }
        
        let auth = Auth.auth()
        do {
            try auth.signOut()
            try self.realm.write {
                realm.delete(currentUser)
            }
            return .success(())
        } catch {
            return .failure(.undefined)
        }
    }
    
    // MARK: - Repositories
    public func getSearchHistory() -> Results<SearchRequest> {
        let searchResults = realm.objects(SearchRequest.self)
        return searchResults
    }
    
    public func createSearchRequest(query: String, perPage: Int) -> SearchRequest {
        let searchRequest = SearchRequest()
        searchRequest.searchQuery = query
        searchRequest.perPage = perPage
        saveSearch(searchRequest)
        return searchRequest
    }
    
    public func searchForRepositories(searchRequest: SearchRequest, threads: Int) -> Observable<GitHubRepository> {
        let currentPage = 1 + searchRequest.results.count / searchRequest.perPage
        
        var searchQueries: [Observable<Response>] = []
        for page in 0 ..< threads {
            let request = apiProvider.rx.request(.searchRepositories(
                token: getCurrentUser()?.token,
                query: searchRequest.searchQuery,
                sort: .stars,
                page: currentPage + page,
                perPage: searchRequest.perPage))
            
            searchQueries.append(request.asObservable())
        }
        
        return Observable.merge(searchQueries)
            .map(SearchRequest.self)
            .flatMap { searchResult in
                Observable.from(searchResult.results)
            }
            .do(onNext: { repository in
                guard !searchRequest.dontSaveNextResults else { return }
                
                try? self.realm.write {
                    searchRequest.results.append(repository)
                    searchRequest.results.sort { $0.stars > $1.stars }
                }
            }, onCompleted: {
                searchRequest.dontSaveNextResults = false
            })
    }
    
    public func saveSearch(_ searchResult: SearchRequest) {
        try? self.realm.write {
            self.realm.add(searchResult)
        }
    }
    
    public func deleteSearch(_ searchRequest: SearchRequest) {
        try? realm.write {
            realm.delete(searchRequest)
        }
    }
}

