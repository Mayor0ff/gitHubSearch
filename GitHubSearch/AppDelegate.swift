//
//  AppDelegate.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        if let rootNavigationController = window?.rootViewController as? UINavigationController,
            let rootViewController = rootNavigationController.topViewController as? MainViewController,
            let gitHubService = try? GitHubService() {
            
            let mainViewModel = MainViewModel(withService: gitHubService)
            rootViewController.viewModel = mainViewModel
        }
        
        return true
    }
}

