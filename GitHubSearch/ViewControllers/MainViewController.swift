//
//  MainViewController.swift
//  GitHubSearch
//
//  Created by Artur Maiorskyi on 25.06.2020.
//  Copyright © 2020 Artur Maiorskyi. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import Kingfisher

class MainViewController: UIViewController {
    public var viewModel: MainViewModel!
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel>(configureCell: {
        (dataSource, tableView, indexPath, item) -> UITableViewCell in
        
        switch item {
        case .auth(let authItem):
            if authItem.isLoggedIn, let currentUser = authItem.currentUser {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "currentUserCell",
                    for: indexPath) as? CurrentUserCell
                else {
                    return UITableViewCell()
                }
                
                cell.usernameLabel.text = currentUser.username
                cell.bioLabel.text = currentUser.bio
                
                if let url = URL(string: currentUser.profilePictureUrl) {
                    cell.profilePictureImageView.kf.setImage(with: url)
                }
                
                cell.signOutButton.rx.tap
                    .subscribe(onNext: self.signOutTap)
                    .disposed(by: cell.disposeBag)
                
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "signInCell",
                    for: indexPath) as? SignInCell
                else {
                    return UITableViewCell()
                }
                
                cell.signInButton.rx.tap
                    .subscribe(onNext: self.onSignInTap)
                    .disposed(by: cell.disposeBag)
                
                return cell
            }
            
        case .repository(let item):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "repositoryCell",
                for: indexPath) as? GitHubRepositoryCell
            else {
                return UITableViewCell()
            }
            
            cell.nameLabel.text = item.name
            
            if let description = item.repositoryDescription {
                if description.count > 30 {
                    let finalIndex = description.index(
                        description.startIndex,
                        offsetBy: 27)
                    cell.descriptionLabel.text = String(description[..<finalIndex]) + "..."
                } else {
                    cell.descriptionLabel.text = description
                }
            }
            
            cell.starsLabel.text = String(item.stars)
            cell.watchersLabel.text = String(item.watchers)
            cell.forksLabel.text = String(item.forks)
            cell.languageLabel.text = item.language
            
            return cell
            
        case .loading:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "loadingCell",
                for: indexPath) as? LoadingCell
            else {
                return UITableViewCell()
            }
            
            cell.stopButton.rx.tap
                .subscribe(onNext: self.viewModel.stopLoadingAction)
                .disposed(by: cell.disposeBag)
            
            return cell
            
        case .searchQuery(let item):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "searchQueryCell",
                for: indexPath) as? SearchQueryCell
            else {
                return UITableViewCell()
            }
            
            cell.searchQuerylabel.text = item.query
            
            return cell
        }
    }, titleForHeaderInSection: { dataSource, index in
        let section = dataSource.sectionModels[index]
        
        switch section {
        case .auth(items: let items):
            return nil
        case .repositories(items: let items):
            return "Repositories"
        case .searchQueries(items: let items):
            return "Search history"
        }
    }, canEditRowAtIndexPath: { dataSource, indexPath in
        switch dataSource.sectionModels[indexPath.section] {
        case .auth:
            return false
        case .repositories:
            return false
        case .searchQueries:
            return true
        }
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search view visibility
        if let searchView = tableView.tableHeaderView {
            viewModel.showSearchBar
                .subscribe(onNext: { showSearchView in
                    searchView.isHidden = !showSearchView
                    searchView.frame.size.height = showSearchView ? 55 : 0
                })
                .disposed(by: disposeBag)
        }
        
        // Prepare for search
        searchField.rx.text
            .subscribe(onNext: { text in
                self.viewModel.willSearchAction(query: text ?? "")
            })
            .disposed(by: disposeBag)
        
        // Search action
        searchField.rx.controlEvent(.editingDidEndOnExit)
            .flatMap(viewModel.searchAction)
            .subscribe(onError: { _ in
                self.showAlert(
                    withTitle: "Error",
                    message: "An error occured. Try again.")
            })
            .disposed(by: disposeBag)
        
        // TableView data source
        viewModel.sections.asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        // Pagination
        tableView.rx.contentOffset
            .filter { offset -> Bool in
                let tableViewMaxOffset = self.tableView.contentSize.height - self.tableView.frame.height
                return tableViewMaxOffset <= offset.y
            }
            .flatMap { _ in self.viewModel.moreResultsAction() }
            .subscribe(onError: { error in
                self.showAlert(
                    withTitle: "Error",
                    message: "An error occured. Try again.")
            })
            .disposed(by: disposeBag)
        
        // Item selection
        tableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
                
                guard let sections = try? self.viewModel.sections.value() else { return }
                let currentSection = sections[indexPath.section]
                
                if case let .repositories(items) = currentSection,
                    case let .repository(item) = items[indexPath.row],
                    let url = URL(string: item.webUrl) {
                    UIApplication.shared.open(url)
                } else if case let .searchQueries(items) = currentSection,
                    case let .searchQuery(item) = items[indexPath.row],
                    let request = item.request {
                    self.viewModel.selectSearchRequest(request)
                }
            })
            .disposed(by: disposeBag)
        
        // Item deletion
        tableView.rx.itemDeleted
            .subscribe(onNext: { indexPath in
                self.viewModel.deleteSearchQuery(at: indexPath.row)
            })
            .disposed(by: disposeBag)
    }
    
    private func onSignInTap() {
        viewModel.signInAction()
            .subscribe(onError: { error in
                self.showAlert(
                    withTitle: "Error",
                    message: "An error occured. Try again.")
            })
            .disposed(by: disposeBag)
    }
    
    private func signOutTap() {
        viewModel.signOutAction()
    }
    
    private func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
