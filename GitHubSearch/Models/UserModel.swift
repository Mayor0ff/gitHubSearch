//
//  UserModel.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RealmSwift

class UserModel: Object, Decodable {
    @objc dynamic var username: String = ""
    @objc dynamic var bio: String = ""
    @objc dynamic var profilePictureUrl: String = ""
    @objc dynamic var token: String = ""
    
    required init() { }
    
    init(username: String, bio: String, profilePictureUrl: String, token: String) {
        self.username = username
        self.bio = bio
        self.profilePictureUrl = profilePictureUrl
        self.token = token
    }
}
