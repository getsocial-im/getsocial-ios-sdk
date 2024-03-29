//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

protocol MyGroupTableViewControllerDelegate {
    func onShowFeed(_ ofGroupId: String)
	func onShowPolls(_ ofGroupId: String)
	func onShowAnnouncementsPolls(_ ofGroupId: String)
    func onShowGroupMembers(_ ofGroupId: String, role: Role)
    func onPostActivity(_ groupId: String)
	func onCreatePoll(_ groupId: String)
    func onEditGroup(_ group: Group)
}

class MyGroupsViewController: UIViewController {

    var viewModel: MyGroupsModel = MyGroupsModel()
    var delegate: MyGroupTableViewControllerDelegate?
    var loadingOlders: Bool = false

    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIDesign.Colors.viewBackground
        self.tableView.register(GroupTableViewCell.self, forCellReuseIdentifier: "grouptableviewcell")
        self.tableView.allowsSelection = false
        self.title = "Groups"

        self.viewModel.onInitialDataLoaded = {
            self.hideActivityIndicatorView()
            self.tableView.reloadData()
        }
        self.viewModel.onDidOlderLoad = { needReload in
            self.hideActivityIndicatorView()
            self.loadingOlders = false
            if needReload {
                self.tableView.reloadData()
            }
        }

        self.viewModel.onError = { error in
            self.hideActivityIndicatorView()
            self.showAlert(withText: error)
        }
        self.viewModel.groupFollowed = { itemIndex in
            self.hideActivityIndicatorView()
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
            self.showAlert(withText: "Group followed")
        }
        self.viewModel.groupUnfollowed = { itemIndex in
            self.hideActivityIndicatorView()
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
            self.showAlert(withText: "Group unfollowed")
        }
        self.viewModel.onGroupDeleted = { itemIndex in
            self.hideActivityIndicatorView()
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.deleteRows(at: [indexToReload], with: .automatic)
            self.showAlert(withText: "Group removed")
        }
        self.viewModel.onGroupLeft = { itemIndex in
            self.hideActivityIndicatorView()
            let indexToDelete = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.deleteRows(at: [indexToDelete], with: .automatic)
            self.showAlert(withText: "Group left")
        }
        self.viewModel.onInviteAccepted = { itemIndex in
            self.hideActivityIndicatorView()
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
            self.showAlert(withText: "Invitation accepted")
        }

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.executeQuery()
    }

    override func viewWillLayoutSubviews() {
        layoutTableView()
    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func executeQuery() {
        self.showActivityIndicatorView()
        self.viewModel.loadEntries()
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

extension MyGroupsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170
    }
}

extension MyGroupsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfEntries()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "grouptableviewcell") as? GroupTableViewCell
        let item = self.viewModel.entry(at: indexPath.row)

        cell?.update(group: item)
        cell?.delegate = self

        return cell ?? UITableViewCell()
    }
}

extension MyGroupsViewController: GroupTableViewCellDelegate {

	func onShowAction(_ groupId: String, isFollowed: Bool) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
        
        if let group = self.viewModel.findGroup(groupId) {
            let role = group.membership?.role
            let status = group.membership?.status
            actionSheet.addAction(UIAlertAction.init(title: "Details", style: .default, handler: { _ in
                self.showAlert(withText: group.description)
            }))
            if !group.settings.isPrivate || status == .member {
                actionSheet.addAction(UIAlertAction.init(title: "Show Feed", style: .default, handler: { _ in
                    self.delegate?.onShowFeed(groupId)
                }))
				actionSheet.addAction(UIAlertAction.init(title: "Activities with Polls", style: .default, handler: { _ in
					self.delegate?.onShowPolls(groupId)
				}))
				actionSheet.addAction(UIAlertAction.init(title: "Announcements with Polls", style: .default, handler: { _ in
					self.delegate?.onShowAnnouncementsPolls(groupId)
				}))
            }
            if status == .member {
                if let role = role {
                    actionSheet.addAction(UIAlertAction.init(title: "Show Members", style: .default, handler: { _ in
                        self.delegate?.onShowGroupMembers(groupId, role: role)
                    }))
                }
                if group.settings.isActionAllowed(action: .post) {
                    actionSheet.addAction(UIAlertAction.init(title: "Post", style: .default, handler: { _ in
                        self.delegate?.onPostActivity(groupId)
                    }))
                }
				if group.settings.isActionAllowed(action: .post) {
					actionSheet.addAction(UIAlertAction.init(title: "Create Poll", style: .default, handler: { _ in
						self.delegate?.onCreatePoll(groupId)
					}))
				}
                if role == .admin || role == .owner {
                    actionSheet.addAction(UIAlertAction.init(title: "Edit", style: .default, handler: { _ in
                        self.delegate?.onEditGroup(group)
                    }))
                    actionSheet.addAction(UIAlertAction.init(title: "Delete", style: .default, handler: { _ in
                        self.viewModel.deleteGroup(groupId)
                    }))
                }
				actionSheet.addAction(UIAlertAction.init(title: isFollowed ? "Unfollow" : "Follow", style: .default, handler: { _ in
					self.showActivityIndicatorView()
					self.viewModel.followGroup(groupId)
				}))
            }
            if status == .invitationPending {
                actionSheet.addAction(UIAlertAction.init(title: "Approve invitation", style: .default, handler: { _ in
                    self.showActivityIndicatorView()
                    self.viewModel.acceptInvite(groupId, membership: group.membership!)
                }))
            }
            if group.membership?.role != .owner {
                actionSheet.addAction(UIAlertAction.init(title: "Leave", style: .default, handler: { _ in
                    self.viewModel.leaveGroup(groupId)
                }))
            }
        }

        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
        
    }
}
