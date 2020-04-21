//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class UsersViewController: UIViewController {

    var viewModel: UsersModel = UsersModel()
    var loadingOlders: Bool = false

    var searchBar: UISearchBar = UISearchBar()
    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .white
        self.tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "usertableviewcell")
        self.tableView.allowsSelection = false

        self.viewModel.onInitialDataLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
        }
        self.viewModel.onDidOlderLoad = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
            self.loadingOlders = false
        }

        self.viewModel.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error.localizedDescription)
        }

        self.tableView.dataSource = self

        self.view.addSubview(self.searchBar)
        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery(searchTerm: nil)
    }

    override func viewWillLayoutSubviews() {
        layoutSearchBar()
        layoutTableView()
    }

    internal func layoutSearchBar() {

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        let top = searchBar.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
        let left = searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)

        NSLayoutConstraint.activate([left, top, right])

        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = self

    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery(searchTerm: String?) {
        self.showActivityIndicatorView()
        let query = UsersQuery.find(searchTerm: searchTerm ?? "")
        self.viewModel.loadEntries(query: query)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height - scrollView.frame.size.height
        if actualPosition > 0 && self.viewModel.numberOfEntries() > 0 && actualPosition > contentHeight && !self.loadingOlders {
            self.loadingOlders = true
            self.showActivityIndicatorView()
            self.viewModel.loadOlder()
        }
    }
}

extension UsersViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.executeQuery(searchTerm: searchBar.text)
    }
}

extension UsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "usertableviewcell") as? UserTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(user: item, isFriend: false)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension UsersViewController: UserTableViewCellDelegate {
    func onUserClicked(_ id: String) {
        if let user = self.viewModel.find(id) {
            self.showAlert(withText: user.description)
        }
    }

    func onFriendButtonClicked(_ id: String, isFriend: Bool) {
    }
}
