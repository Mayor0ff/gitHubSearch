//
//  ViewModel.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import Foundation

protocol ViewModel {
    associatedtype Service
    init(withService service: Service)
}
