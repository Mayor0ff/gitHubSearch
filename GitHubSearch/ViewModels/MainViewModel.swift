//
//  MainViewModel.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RxSwift
import RxDataSources

struct AuthItem {
    var isLoggedIn: Bool
    var currentUser: UserModel?
}

struct SearchQueryItem {
    var query: String
    var request: SearchRequest?
}

enum SectionModel {
    case auth(items: [SectionItem])
    case repositories(items: [SectionItem])
    case searchQueries(items: [SectionItem])
}

enum SectionItem {
    case auth(item: AuthItem)
    case repository(item: GitHubRepository)
    case searchQuery(item: SearchQueryItem)
    case loading
}

extension SectionModel: SectionModelType {
    var items: [SectionItem] {
        switch self {
        case .auth(let items):
            return items
        case .repositories(let items):
            return items
        case .searchQueries(let items):
            return items
        }
    }
    
    init(original: SectionModel, items: [SectionItem]) {
        switch original {
        case .auth:
            self = .auth(items: items)
        case .repositories:
            self = .repositories(items: items)
        case .searchQueries:
            self = .searchQueries(items: items)
        }
    }
}

class MainViewModel: ViewModel {
    private var service: GitHubService
    
    private var searchQuery: String
    private var searchRequest: SearchRequest?
    private var isLoading: Bool
    
    public var showSearchBar: BehaviorSubject<Bool>
    public var sections: BehaviorSubject<[SectionModel]>
    
    required init(withService service: GitHubService) {
        self.service = service
        
        self.searchQuery = ""
        self.isLoading = false
        
        self.showSearchBar = BehaviorSubject(value: service.getCurrentUser() != nil)
        self.sections = BehaviorSubject(value: [])
        
        self.updateSections()
    }
    
    private func updateSections() {
        var newSections: [SectionModel] = []
        
        let authItem = service.getCurrentUser().map {
            AuthItem(isLoggedIn: true, currentUser: $0)
        } ?? AuthItem(isLoggedIn: false, currentUser: nil)
        
        newSections.append(.auth(items: [.auth(item: authItem)]))
        
        var queryItems: [SectionItem] = []

        for searchRequest in service.getSearchHistory() {
            let searchQueryItem = SearchQueryItem(
                query: searchRequest.searchQuery,
                request: searchRequest)

            queryItems.append(.searchQuery(item: searchQueryItem))
        }

        if queryItems.count > 0 {
            newSections.append(.searchQueries(items: queryItems))
        }
        
        if let searchRequest = searchRequest {
            var repositories: [SectionItem] = []
            
            for repository in searchRequest.results {
                repositories.append(.repository(item: repository))
            }
            
            if isLoading {
                repositories.append(.loading)
            }
            
            if repositories.count > 0 {
                newSections.append(.repositories(items: repositories))
            }
        }
        
        sections.onNext(newSections)
    }
    
    public func signInAction() -> Single<UserModel> {
        self.service.signIn()
            .do(onSuccess: { userModel in
                self.showSearchBar.onNext(true)
                self.searchRequest = nil
                self.updateSections()
            })
    }
    
    public func signOutAction() -> Result<Void, GitHubService.SignOutError> {
        self.showSearchBar.onNext(false)
        self.searchRequest = nil
        
        let result = self.service.signOut()
        self.updateSections()
        
        return result
    }
    
    public func willSearchAction(query: String) {
        self.searchQuery = query
        self.updateSections()
    }
    
    public func selectSearchRequest(_ searchRequest: SearchRequest) {
        self.searchRequest = searchRequest
        self.updateSections()
    }
    
    public func searchAction() -> Observable<GitHubRepository> {
        guard searchQuery.count > 0 else { return .empty() }
        
        let request = service.createSearchRequest(query: self.searchQuery, perPage: 15)
        self.searchRequest = request
        
        return loadResults(forRequest: request)
    }
    
    public func moreResultsAction() -> Observable<GitHubRepository> {
        guard !isLoading,
            service.getCurrentUser() != nil,
            let request = searchRequest,
            request.results.count > 0
        else { return .empty() }
        
        self.isLoading = true
        self.updateSections()
        
        return loadResults(forRequest: request)
    }
    
    private func loadResults(forRequest request: SearchRequest) -> Observable<GitHubRepository> {
        self.isLoading = true
        self.updateSections()
        
        return self.service.searchForRepositories(searchRequest: request, threads: 2)
            .do(onNext: { _ in
                self.updateSections()
            }, onError: { _ in
                self.isLoading = false
                self.updateSections()
            }, onCompleted: {
                self.isLoading = false
                self.updateSections()
            })
    }
    
    public func stopLoadingAction() {
        self.searchRequest?.dontSaveNextResults = true
        self.isLoading = false
        self.updateSections()
    }
    
    public func deleteSearchQuery(at index: Int) {
        let searchQuery = service.getSearchHistory()[index]
        self.service.deleteSearch(searchQuery)
        self.updateSections()
    }
}
