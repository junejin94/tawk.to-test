//
//  ViewController.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import Combine
import Network
import UIKit
import SwiftUI

class ListView: UIViewController {
    var viewModel: UsersViewModel?

    private var indicator = UILabel()

    private var triggerLoad: Bool = false
    private var hasConnection: Bool = false
    private var disposables = Set<AnyCancellable>()
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var tableView: UITableView = UITableView()
    private var constraintBannerHeight: NSLayoutConstraint!
    private var searchBar: UISearchController = UISearchController()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        viewModel = UsersViewModel()

        initSearchBar()
        initTableView()
        initIndicator()
        initCancellable()
        initActivityIndicator()

        viewModel?.loadData()
    }

    func initActivityIndicator() {
        activityIndicator.center = view.center

        view.addSubview(activityIndicator)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }

    func initTableView() {
        tableView.layoutMargins = .init(top: 100, left: 100, bottom: 100, right: 100)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.registerCell(cellClass: CustomCellNormal.self)
        tableView.registerCell(cellClass: CustomCellNote.self)
        tableView.registerCell(cellClass: CustomCellInverted.self)
        
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        tableView.rightAnchor.constraint(equalTo:view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        tableView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    func initSearchBar() {
        searchBar.delegate = self
        searchBar.searchResultsUpdater = self
        searchBar.searchBar.placeholder = "Search..."
        searchBar.searchBar.autocapitalizationType = .none
        searchBar.obscuresBackgroundDuringPresentation = false
        searchBar.hidesNavigationBarDuringPresentation = false

        navigationItem.searchController = searchBar
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    func initIndicator() {
        indicator.textColor = .white
        indicator.textAlignment = .center
        indicator.font = UIFont.systemFont(ofSize: 12)
 
        if let navBar = self.navigationController?.navigationBar {
            navBar.addSubview(indicator)

            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.leadingAnchor.constraint(equalTo: navBar.leadingAnchor).isActive = true
            indicator.trailingAnchor.constraint(equalTo: navBar.trailingAnchor).isActive = true
            indicator.topAnchor.constraint(equalTo: navBar.topAnchor).isActive = true

            constraintBannerHeight = indicator.heightAnchor.constraint(equalToConstant: 0)
            constraintBannerHeight.isActive = true
        }
    }

    func initCancellable() {
        // The reason didSet was used is because Observable triggers on willSet which the data has not been set yet
        viewModel?.didSetList.sink { _ in
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.tableView.reloadData()
                self?.triggerLoad = false
            }
        }.store(in: &disposables)

        MonitorConnection.shared.$hasConnection.sink { hasConnection in
            DispatchQueue.main.async { [weak self] in
                self?.hasConnection = hasConnection
                self?.indicator.text = hasConnection ? "Connection is back" : "No internet connection"
                self?.indicator.backgroundColor = hasConnection ? .green : .red

                DispatchQueue.main.asyncAfter(deadline: .now() + (hasConnection ? 2 : 0), execute: {
                    UIView.animate(withDuration: 0.5, animations: {
                        self?.constraintBannerHeight.constant = hasConnection ? 0 : 20
                        self?.navigationController?.navigationBar.superview?.layoutIfNeeded()
                    })
                })
            }
        }.store(in: &disposables)
    }
}

extension ListView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.userList.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .zero
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return emptyView()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = viewModel!.cellForTableView(tableView: tableView, atIndexPath: indexPath)
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let data = viewModel?.userList[indexPath.section] {
            var title: String? = ""

            if let detail = data.detail {
                title = detail.name
            } else {
                if !hasConnection {
                    let msg = UIAlertController(title: "", message: "There's no internet connection.\nPlease try again later.", preferredStyle: .alert)
                    msg.addAction(UIAlertAction(title: "OK", style: .default))

                    self.present(msg, animated: true)
                    return
                }
            }

            data.didSetNotes.sink { _ in
                DispatchQueue.main.async { tableView.reloadData() }
            }.store(in: &disposables)

            let view = UIHostingController(rootView: DetailsView().environmentObject(data))
            view.title = title

            self.navigationController?.pushViewController(view, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !triggerLoad, hasConnection, indexPath.section + 1 == viewModel?.allList.count {
            triggerLoad = true
            self.activityIndicator.startAnimating()
            viewModel?.loadMore()
        }
    }
}

extension ListView: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel?.filterList(text: searchController.searchBar.text ?? "")
    }
}
