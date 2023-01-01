//
//  ListView.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import Combine
import Network
import UIKit
import SwiftUI

@MainActor class ListView: UIViewController, SkeletonDisplayable {
    private var viewModel: ListViewModel
    private var indicator = UILabel()
    private var showSkeleton: Bool = true
    private var triggerLoad: Bool = false
    private var hasConnection: Bool = false
    private var disposables = Set<AnyCancellable>()
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var tableView: UITableView = UITableView()
    private var constraintBannerHeight: NSLayoutConstraint!
    private var searchBar: UISearchController = UISearchController()

    init(viewModel: ListViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = ListViewModel()

        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        initData()
        initSearchBar()
        initTableView()
        initIndicator()
        initCancellable()
        initActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if showSkeleton { showSkeleton() }
    }

    private func initData() {
        loadData()
    }

    private func initActivityIndicator() {
        activityIndicator.center = tableView.center
        activityIndicator.frame = view.frame
        activityIndicator.hidesWhenStopped = true

        view.addSubview(activityIndicator)
    }

    private func initTableView() {
        tableView.layoutMargins = .init(top: 100, left: 100, bottom: 100, right: 100)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.isScrollEnabled = false
        tableView.isUserInteractionEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.registerCell(cellClass: CustomCellNormal.self)
        tableView.registerCell(cellClass: CustomCellNote.self)
        tableView.registerCell(cellClass: CustomCellInverted.self)
        tableView.registerCell(cellClass: CustomCellShimmer.self)

        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        tableView.rightAnchor.constraint(equalTo:view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        tableView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    private func initSearchBar() {
        searchBar.delegate = self
        searchBar.searchResultsUpdater = self
        searchBar.searchBar.placeholder = "Search..."
        searchBar.searchBar.autocapitalizationType = .none
        searchBar.searchBar.isUserInteractionEnabled = false
        searchBar.obscuresBackgroundDuringPresentation = false
        searchBar.hidesNavigationBarDuringPresentation = false

        navigationItem.searchController = searchBar
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func initIndicator() {
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

    private func initCancellable() {
        /// The reason didSet was used is because Observable triggers on willSet which the data has not been set yet
        viewModel.didSetList.sink { _ in
            self.triggerLoad = false

            self.activityIndicator.stopAnimating()
            self.tableView.reloadData()
            self.enableInteraction()
        }.store(in: &disposables)

        MonitorConnection.shared.$hasConnection.dropFirst().sink { hasConnection in
            Task {
                self.hasConnection = hasConnection
                self.indicator.text = hasConnection ? "Connection is back" : "No internet connection"
                self.indicator.backgroundColor = hasConnection ? .green : .red

                try? await Task.sleep(seconds: hasConnection ? 2 : 0)

                if hasConnection { self.retryIfNecessary() }

                UIView.animate(withDuration: 0.5, animations: {
                    self.constraintBannerHeight.constant = hasConnection ? 0 : 20
                    self.navigationController?.navigationBar.superview?.layoutIfNeeded()
                })
            }
        }.store(in: &disposables)
    }

    private func loadData() {
        Task.detached { [weak self] in await self?.viewModel.loadData() }
    }

    private func loadMore() {
        Task.detached { [weak self] in await self?.viewModel.loadMore() }
    }

    private func retryIfNecessary() {
        Task { await viewModel.retryIfNecessary() }
    }

    private func enableInteraction() {
        hideSkeleton()

        showSkeleton = false
        tableView.isScrollEnabled = true
        tableView.isUserInteractionEnabled = true
        searchBar.searchBar.isUserInteractionEnabled = true
    }
}

extension ListView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.allList.count == 0 ? 10 : viewModel.userList.count
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
        return viewModel.cellForTableView(tableView: tableView, atIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let data = viewModel.getUser(indexPath: indexPath) {
            let detailsViewModel = DetailsViewModel(user: data)

            Publishers.MergeMany(detailsViewModel.didSetDetail, detailsViewModel.didSetSeen).sink { _ in
                Task { tableView.reloadData() }
            }.store(in: &disposables)

            detailsViewModel.didSetNotes.sink { notes in
                data.notes = notes
                Task { tableView.reloadData() }
            }.store(in: &disposables)

            let view = UIHostingController(rootView: DetailsView().environmentObject(detailsViewModel))

            if let detail = data.detail { view.title = detail.name }

            self.navigationController?.pushViewController(view, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        Task {
            if !triggerLoad, indexPath.section + 1 == viewModel.allList.count {
                triggerLoad = true

                activityIndicator.startAnimating()
                loadMore()
            }
        }
    }
}

extension ListView: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        Task { await viewModel.filterList(text: searchController.searchBar.text ?? "") }
    }
}
