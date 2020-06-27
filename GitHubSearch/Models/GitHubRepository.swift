//
//  SearchHistoryElement.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RealmSwift

class GitHubRepository: Object, Decodable {
    @objc dynamic var id: Int = 0
    
    @objc dynamic var name: String = ""
    @objc dynamic var repositoryDescription: String? = nil
    @objc dynamic var language: String? = nil
    
    @objc dynamic var stars: Int = 0
    @objc dynamic var watchers: Int = 0
    @objc dynamic var forks: Int = 0
    
    @objc dynamic var webUrl: String = ""
    
    @objc dynamic var viewed: Bool = false
    
    required init() {}
    
    // MARK: Decodable
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "full_name"
        case repositoryDescription = "description"
        case language = "language"
        case stars = "stargazers_count"
        case watchers = "watchers_count"
        case forks = "forks_count"
        case webUrl = "html_url"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.repositoryDescription = try? container.decode(String.self, forKey: .repositoryDescription)
        self.language = try? container.decode(String.self, forKey: .language)
        
        self.stars = try container.decode(Int.self, forKey: .stars)
        self.watchers = try container.decode(Int.self, forKey: .watchers)
        self.forks = try container.decode(Int.self, forKey: .forks)
        
        self.webUrl = try container.decode(String.self, forKey: .webUrl)
    }
}
