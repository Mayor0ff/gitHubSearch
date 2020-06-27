//
//  OAuthProvider+Rx.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import RxSwift
import FirebaseAuth

extension Reactive where Base: OAuthProvider {
    public func getCredentialWith(_ UIDelegate: AuthUIDelegate?, skipError: Bool) -> Single<AuthCredential> {
        Single<AuthCredential>.create { observer in
            self.base.getCredentialWith(UIDelegate) { (credential, error) in
                if let credential = credential {
                    observer(.success(credential))
                }
                
                // Skips "User interaction is still ongoing" error
                if !skipError, let error = error {
                    observer(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
}
