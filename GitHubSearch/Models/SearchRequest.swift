//
//  SearchResult.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RealmSwift
import RxSwift

class SearchRequest: Object, Decodable {
    @objc dynamic var searchQuery: String = ""
    @objc dynamic var perPage: Int = 0
    public var dontSaveNextResults: Bool = false
    
    var results = List<GitHubRepository>()
    
    required init () {}
    
    // MARK: Decodable
    enum CodingKeys: String, CodingKey {
        case items
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedResults = try container.decode([GitHubRepository].self, forKey: .items)
        self.results.append(objectsIn: decodedResults)
    }
}
