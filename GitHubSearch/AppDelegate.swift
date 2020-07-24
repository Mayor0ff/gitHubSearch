//
//  AppDelegate.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        guard let rootNC = window?.rootViewController as? UINavigationController,
            let rootVC = rootNC.topViewController as? MainViewController
        else {
            preconditionFailure("Root view controller not found")
        }
        
        let realm = try! Realm()
        let gitHubService = GitHubService(realm: realm)
        let openUrlService = ApplicationOpenUrlService()
        
        let mainViewModel = MainViewModel(
            withService: gitHubService,
            openUrlService: openUrlService)
        rootVC.viewModel = mainViewModel
        
        return true
    }
}

