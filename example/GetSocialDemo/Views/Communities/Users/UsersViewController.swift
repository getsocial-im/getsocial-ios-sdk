//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol UsersViewControllerDelegate {
    func onFollowersClicked(ofUser: UserId, followersCount: Int)
    func onFollowingsClicked(ofUser: UserId)
}

class UsersViewController: UIViewController {

    var viewModel: UsersModel = UsersModel()
    var loadingOlders: Bool = false
    var query: UsersQuery?

    var searchBar: UISearchBar = UISearchBar()
    var tableView: UITableView = UITableView()
    var delegate: UsersViewControllerDelegate?

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
        self.viewModel.onFriendStatusUpdated = { rowIndex in
            self.hideActivityIndicatorView()
            self.tableView.reloadRows(at: [IndexPath.init(row: rowIndex, section: 0)], with: .automatic)
        }
        self.viewModel.onFollowStatusUpdated = { rowIndex in
            self.hideActivityIndicatorView()
            self.tableView.reloadRows(at: [IndexPath.init(row: rowIndex, section: 0)], with: .automatic)
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.addSubview(self.searchBar)
        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery()
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
        var query: UsersQuery
        
        if (searchTerm != nil && searchTerm != "") {
            query = UsersQuery.find(searchTerm ?? "")
        } else {
            query = UsersQuery.suggested()
        }
        
        self.viewModel.loadEntries(query: query)
    }

    private func executeQuery() {
        if (self.query == nil) {
            executeQuery(searchTerm: nil)
        } else {
            self.showActivityIndicatorView()
            self.viewModel.loadEntries(query: self.query!)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height - scrollView.frame.size.height
        if actualPosition > 0 && self.viewModel.numberOfEntries() > 0 && actualPosition > contentHeight && !self.loadingOlders && self.viewModel.nextCursor.count != 0 {
            self.loadingOlders = true
            self.showActivityIndicatorView()
            self.viewModel.loadOlder()
        }
    }
}

extension UsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
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

        let isFriend = self.viewModel.friendsStatuses[item.userId] ?? false
        let isFollowed = self.viewModel.followStatuses[item.userId] ?? false
        let followersCount = self.viewModel.followersCount[item.userId] ?? 0
        cell?.update(user: item, isFriend: isFriend, isFollowed: isFollowed, followersCount: followersCount)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension UsersViewController: UserTableViewCellDelegate {
    func onShowActions(_ id: String, isFollowed: Bool, isFriend: Bool, followersCount: Int) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction.init(title: "Details", style: .default, handler: { _ in
            if let user = self.viewModel.find(id) {
                self.showAlert(withText: user.description)
            }
        }))
        if id != GetSocial.currentUser()?.userId {
            actionSheet.addAction(UIAlertAction.init(title: isFriend ? "Remove friend" : "Add friend", style: .default, handler: { _ in
                self.showActivityIndicatorView()
                self.viewModel.updateFriendsStatus(of: id, newStatus: !isFriend)
            }))
            actionSheet.addAction(UIAlertAction.init(title: isFollowed ? "Unfollow" : "Follow", style: .default, handler: { _ in
                self.showActivityIndicatorView()
                self.viewModel.updateFollowStatus(of: id, newStatus: !isFollowed)
            }))
        }
        actionSheet.addAction(UIAlertAction.init(title: "Followers", style: .default, handler: { _ in
            self.delegate?.onFollowersClicked(ofUser: UserId.create(id), followersCount: followersCount)
        }))
        actionSheet.addAction(UIAlertAction.init(title: "Followings", style: .default, handler: { _ in
            self.delegate?.onFollowingsClicked(ofUser: UserId.create(id))
        }))
        actionSheet.addAction(UIAlertAction.init(title: "User's posts", style: .default, handler: { _ in
            let query = ActivitiesQuery.everywhere().byUser(UserId(id))
            GetSocialUIActivityFeedView(for: query).show()
        }))
        actionSheet.addAction(UIAlertAction.init(title: "User's feed", style: .default, handler: { _ in
            let query = ActivitiesQuery.feedOf(UserId.create(id))
            GetSocialUIActivityFeedView(for: query).show()
        }))
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
}
