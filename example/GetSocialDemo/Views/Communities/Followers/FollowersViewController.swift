//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class FollowersViewController: UIViewController {

    var viewModel: FollowersModel = FollowersModel()
    var query: FollowersQuery?
    var loadingOlders: Bool = false

    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.title = "hello"
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
        self.viewModel.onDidFollowersCount = { counter in
            self.hideActivityIndicatorView()
            self.title = "\(counter) follower" + (counter > 1 ? "s" : "")
        }
        self.viewModel.onFriendStatusUpdated = { rowIndex in
            self.hideActivityIndicatorView()
            self.tableView.reloadRows(at: [IndexPath.init(row: rowIndex, section: 0)], with: .automatic)
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.addSubview(self.tableView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        executeQuery()
    }

    override func viewWillLayoutSubviews() {
        layoutTableView()
    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery() {
        self.showActivityIndicatorView()
        self.viewModel.loadEntries(query: self.query ?? FollowersQuery.ofTopic(id: "global"))
        self.viewModel.loadFollowersCount(query: self.query ?? FollowersQuery.ofTopic(id: "global"))
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

extension FollowersViewController: UITableViewDelegate {

}

extension FollowersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "usertableviewcell") as? UserTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(user: item, isFriend: self.viewModel.friendsStatuses[item.userId] ?? false)
        cell?.delegate = self
        return cell ?? UITableViewCell()
    }
}

extension FollowersViewController: UserTableViewCellDelegate {
    func onUserClicked(_ id: String) {
        if let user = self.viewModel.find(id) {
            self.showAlert(withText: user.description)
        }
    }

    func onFriendButtonClicked(_ id: String, isFriend: Bool) {
        self.showActivityIndicatorView()
        self.viewModel.updateFriendsStatus(of: id, newStatus: !isFriend)
    }

}
