//
//  SearchResult.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RealmSwift

class SearchRequest: Object, Decodable {
    @objc dynamic var searchQuery: String = ""
    @objc dynamic var results: [GitHubRepository] = []
    @objc dynamic var perPage: Int = 0
    
    required init () {}
    
    // MARK: Decodable
    enum CodingKeys: String, CodingKey {
        case items
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([GitHubRepository].self, forKey: .items)
    }
}
