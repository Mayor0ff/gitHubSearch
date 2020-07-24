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
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel>(
        configureCell: configureCell,
        titleForHeaderInSection: titleForHeaderInSection,
        canEditRowAtIndexPath: canEditRowAtIndexPath)
    
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
                    case let .repository(item) = items[indexPath.row] {
                    self.viewModel.selectRepository(item)
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
    
    // MARK: Table View
    private func configureCell(
        dataSource: TableViewSectionedDataSource<SectionModel>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: SectionItem
    ) -> UITableViewCell {
        switch item {
        case .auth(let authItem):
            if authItem.isLoggedIn, let currentUser = authItem.currentUser {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "currentUserCell",
                    for: indexPath) as! CurrentUserCell
                
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
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "signInCell",
                    for: indexPath) as! SignInCell
                
                cell.signInButton.rx.tap
                    .subscribe(onNext: self.onSignInTap)
                    .disposed(by: cell.disposeBag)
                
                return cell
            }
            
        case .repository(let item):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "repositoryCell",
                for: indexPath) as! GitHubRepositoryCell
            
            cell.nameLabel.text = item.name
            cell.descriptionLabel.text =  item.repositoryDescription
            cell.starsLabel.text = String(item.stars)
            cell.watchersLabel.text = String(item.watchers)
            cell.forksLabel.text = String(item.forks)
            cell.languageLabel.text = item.language
            cell.viewedLabel.isHidden = !item.viewed
            
            return cell
            
        case .loading:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "loadingCell",
                for: indexPath) as! LoadingCell
            
            cell.stopButton.rx.tap
                .subscribe(onNext: self.viewModel.stopLoadingAction)
                .disposed(by: cell.disposeBag)
            
            return cell
            
        case .searchQuery(let item):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "searchQueryCell",
                for: indexPath) as! SearchQueryCell
            
            cell.searchQuerylabel.text = item.query
            
            return cell
        }
    }
    
    private func titleForHeaderInSection(
        dataSource: TableViewSectionedDataSource<SectionModel>,
        index: Int
    ) -> String? {
        let section = dataSource.sectionModels[index]
        switch section {
        case .auth:
            return nil
        case .repositories:
            return "Repositories"
        case .searchQueries:
            return "Search history"
        }
    }
    
    private func canEditRowAtIndexPath(
        dataSource: TableViewSectionedDataSource<SectionModel>,
        indexPath: IndexPath
    ) -> Bool {
        switch dataSource.sectionModels[indexPath.section] {
        case .auth:
            return false
        case .repositories:
            return false
        case .searchQueries:
            return true
        }
    }
    
    // MARK: Actions
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
