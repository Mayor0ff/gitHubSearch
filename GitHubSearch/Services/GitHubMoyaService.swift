//
//  GitHubMoyaService.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import Moya

enum GitHubMoyaService {
    enum SearchRepositoriesSort: String {
        case stars
        case forks
    }
    
    case searchRepositories(token: String?, query: String, sort: SearchRepositoriesSort, page: Int, perPage: Int)
}

extension GitHubMoyaService: TargetType {
    var baseURL: URL { URL(string: "https://api.github.com")! }
    
    var path: String {
        switch self {
        case .searchRepositories:
            return "/search/repositories"
        }
    }
    
    var method: Method {
        switch self {
        case .searchRepositories:
            return .get
        }
    }
    
    var sampleData: Data {
        Data()
    }
    
    var task: Task {
        switch self {
        case let .searchRepositories(_, query, sort, page, perPage):
            return .requestParameters(
                parameters: ["q": query, "sort": sort.rawValue, "page": page, "per_page": perPage],
                encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case let .searchRepositories(token, _, _, _, _):
            if let token = token {
                return ["Authorization": "token \(token)"]
            }
            
            return nil
        }
    }
}
