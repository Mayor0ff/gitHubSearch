//
//  SignInCell.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 26.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SignInCell: UITableViewCell {
    @IBOutlet weak var signInButton: UIButton!
    
    public var disposeBag = DisposeBag()
}
