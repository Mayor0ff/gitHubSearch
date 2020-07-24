//
//  LoadingCell.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 27.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit
import RxSwift

class LoadingCell: UITableViewCell {
    @IBOutlet weak var stopButton: UIButton!
    
    public let disposeBag = DisposeBag()
}
