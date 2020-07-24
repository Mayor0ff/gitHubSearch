//
//  SearchCell.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 26.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit
import RxSwift

class SearchCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    
    public let disposeBag = DisposeBag()
}
