//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class UsersByIdViewController: UIViewController {

    var viewModel: UsersByIdModel = UsersByIdModel()

    var providerIdField: UITextField = UITextField()
    var tableView: UITableView = UITableView()
    var actionButton: UIBarButtonItem = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.tableView.backgroundColor = .white
        self.tableView.register(UserIdCellView.self, forCellReuseIdentifier: "useridtableviewcell")
        self.tableView.allowsSelection = false
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 48
        self.tableView.delegate = self

        self.viewModel.onRowAdded = { rowNum in
            self.view.endEditing(false)
            self.tableView.insertRows(at: [IndexPath.init(item: rowNum, section: 0)], with: .bottom)
        }
        self.viewModel.onOperationFinished = { result in
            self.hideActivityIndicatorView()
            self.showAlert(withText: result)
        }
        self.viewModel.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error.localizedDescription)
        }

        self.tableView.dataSource = self

        self.view.addSubview(self.providerIdField)
        self.view.addSubview(self.tableView)

        let addIdButton: UIBarButtonItem = UIBarButtonItem.init(title: "+", style: .plain, target: self, action: #selector(addUserIdRow(sender:)))
        addIdButton.isEnabled = true

        actionButton = UIBarButtonItem.init(title: "Action", style: .plain, target: self, action: #selector(showActions(sender:)))

        self.navigationItem.rightBarButtonItems = [actionButton, addIdButton]

    }

    @objc
    func addUserIdRow(sender: Any?) {
        self.viewModel.addRow()
    }

    @objc
    func showActions(sender: Any?) {
        self.showActionsSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillLayoutSubviews() {
        layoutProviderIdField()
        layoutTableView()
    }

    internal func layoutProviderIdField() {
        providerIdField.translatesAutoresizingMaskIntoConstraints = false
        let top = providerIdField.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
        let left = providerIdField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 4)
        let right = providerIdField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 4)
        let height = providerIdField.heightAnchor.constraint(equalToConstant: 40.0)

        self.providerIdField.backgroundColor = .white
        self.providerIdField.borderStyle = .roundedRect
        self.providerIdField.layer.borderColor = UIColor.darkGray.cgColor
        self.providerIdField.placeholder = "Provider Id"
        NSLayoutConstraint.activate([left, top, right, height])
    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.providerIdField.bottomAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery(searchTerm: String?) {
        self.showActivityIndicatorView()
    }
}

extension UsersByIdViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
}

extension UsersByIdViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfEntries = self.viewModel.numberOfEntries()
        actionButton.isEnabled = numberOfEntries > 0
        return numberOfEntries
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "useridtableviewcell") as? UserIdCellView
        let userId = self.viewModel.entry(at: indexPath.row)

        cell?.updateContent(userId: userId)
        cell?.onFinishedEditing = { newValue in
            self.viewModel.updateEntry(at: indexPath.row, value: newValue)
        }
        cell?.setNeedsLayout()

        return cell ?? UITableViewCell()
    }
}

extension UsersByIdViewController {
    func showActionsSheet() {
        self.view.endEditing(false)
        let actionSheet = UIAlertController.init(title: "Choose action", message: nil, preferredStyle: .actionSheet)
        let addFriendsAction = UIAlertAction.init(title: "Add Friends", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.addFriends(providerId: self.providerIdField.text)
        })
        let removeFriendsAction = UIAlertAction.init(title: "Remove Friends", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.removeFriends(providerId: self.providerIdField.text)
        })
        let areFriendsAction = UIAlertAction.init(title: "Are Friends", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.areFriends(providerId: self.providerIdField.text)
        })
        let setFriendsAction = UIAlertAction.init(title: "Set Friends", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.setFriends(providerId: self.providerIdField.text)
        })
        let sendNotificationAction = UIAlertAction.init(title: "Send Notification", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.sendNotification(providerId: self.providerIdField.text)
        })
        let followUsersAction = UIAlertAction.init(title: "Follow Users", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.followUsers(providerId: self.providerIdField.text)
        })
        let unfollowUsersAction = UIAlertAction.init(title: "Unfollow Users", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.unfollowUsers(providerId: self.providerIdField.text)
        })
        let isFollowingUsersAction = UIAlertAction.init(title: "Is Following Users", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.isFollowingUsers(providerId: self.providerIdField.text)
        })
        let findUsersAction = UIAlertAction.init(title: "Find Users", style: .default, handler: { _ in
            self.showActivityIndicatorView()
            self.viewModel.findUsers(providerId: self.providerIdField.text)
        })
        actionSheet.addAction(addFriendsAction)
        actionSheet.addAction(removeFriendsAction)
        actionSheet.addAction(areFriendsAction)
        actionSheet.addAction(setFriendsAction)
        actionSheet.addAction(sendNotificationAction)
        actionSheet.addAction(followUsersAction)
        actionSheet.addAction(unfollowUsersAction)
        actionSheet.addAction(isFollowingUsersAction)
        actionSheet.addAction(findUsersAction)
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
}
