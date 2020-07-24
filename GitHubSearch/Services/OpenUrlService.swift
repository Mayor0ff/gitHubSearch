//
//  OpenUrlService.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 24.07.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit

protocol OpenUrlService {
    @discardableResult
    func openUrl(url: URL) -> Bool
    
    init()
}

// Сервис нужен, чтоб убрать зависимость от UIApplication
// для того, чтоб класс с ViewModel можно было тестировать в другой среде
class ApplicationOpenUrlService: OpenUrlService {
    @discardableResult
    public func openUrl(url: URL) -> Bool {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        
        return false
    }
    
    required public init() {}
}
