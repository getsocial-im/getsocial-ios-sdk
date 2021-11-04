//
//  GenericPagingViewController.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialSDK

protocol GroupTableViewControllerDelegate {
	func onShowFeed(_ ofGroupId: String, byCurrentUser: Bool)
	func onShowPolls(_ ofGroupId: String)
	func onShowAnnouncementsPolls(_ ofGroupId: String)
    func onShowGroupMembers(_ ofGroupId: String, role: Role)
    func onPostActivity(_ groupId: String)
	func onCreatePoll(_ groupId: String)
    func onEditGroup(_ group: Group)
	func onShowPlainFeed(_ ofTopic: String)
}

class GroupsViewController: UIViewController {

    var viewModel: GroupsModel = GroupsModel()
    var delegate: GroupTableViewControllerDelegate?
    var loadingOlders: Bool = false

    var textSearchBar: UISearchBar = UISearchBar()
	var labelSearchBar = UISearchBar()
	var propertySearchBar = UISearchBar()

    var tableView: UITableView = UITableView()

	var sortBy: String?
	var sortOrder: String?
	var showOnlyTrending = false

	var sortButton: UIBarButtonItem!
	var trendingButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIDesign.Colors.viewBackground
        self.tableView.register(GroupTableViewCell.self, forCellReuseIdentifier: "grouptableviewcell")
        self.tableView.allowsSelection = false
        self.title = "Groups"

		self.sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(showSort))
		self.trendingButton = UIBarButtonItem(title: "Only Trending", style: .plain, target: self, action: #selector(showTrending))
		self.navigationItem.rightBarButtonItems = [trendingButton]

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
        self.viewModel.onGroupJoined = { (groupMember, itemIndex) in
            self.hideActivityIndicatorView()
            if groupMember.membership.status == .member {
                self.showAlert(withText: "Joined to group: \(groupMember)")
            }
            if groupMember.membership.status == .approvalPending {
                self.showAlert(withText: "Asked to join to group: \(groupMember)")
            }
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
        }
        self.viewModel.onGroupLeft = { itemIndex in
            self.hideActivityIndicatorView()
            let indexToReload = IndexPath.init(row: itemIndex, section: 0)
            self.tableView.reloadRows(at: [indexToReload], with: .automatic)
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

        self.view.addSubview(self.textSearchBar)
		self.view.addSubview(self.labelSearchBar)
		self.view.addSubview(self.propertySearchBar)
        self.view.addSubview(self.tableView)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		self.executeQuery(searchTerm: self.textSearchBar.text, label: self.labelSearchBar.text, property: self.propertySearchBar.text)
    }

    override func viewWillLayoutSubviews() {
        layoutSearchFields()
        layoutTableView()
    }

	@objc
	func showTrending(sender: Any?) {
		self.showOnlyTrending.toggle()
		self.sortButton.isEnabled = !self.showOnlyTrending
		self.trendingButton.title = self.showOnlyTrending ? "All": "Only Trending"
		// use default sorting after changing isTrending
		self.sortBy = nil
		self.sortOrder = nil
		self.executeQuery(searchTerm: self.textSearchBar.text, label: self.labelSearchBar.text, property: self.propertySearchBar.text)
	}

	@objc
	func showSort(sender: Any?) {
		var sortOptions: [(String, String)] = []
		if self.showOnlyTrending {
			sortOptions = []
		} else {
			sortOptions = [
				("id",""),
				("id","-"),
				("createdAt",""),
				("createdAt","-")]
		}
		let vc = SortOrderDialog(sortOptions, selectedOptionIndex: 3)
		vc.onOptionSelected = { selectedIndex in
			self.sortBy = sortOptions[selectedIndex].0
			self.sortOrder = sortOptions[selectedIndex].1
			self.navigationController?.popViewController(animated: true)
		}
		self.navigationController?.pushViewController(vc, animated: true)
	}

    internal func layoutSearchFields() {

        textSearchBar.translatesAutoresizingMaskIntoConstraints = false
        let top = textSearchBar.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
        let left = textSearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = textSearchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)

        NSLayoutConstraint.activate([left, top, right])

		textSearchBar.enablesReturnKeyAutomatically = false
		textSearchBar.delegate = self

		labelSearchBar.translatesAutoresizingMaskIntoConstraints = false
		labelSearchBar.placeholder = "label1,label2"
		NSLayoutConstraint.activate([
			self.labelSearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			self.labelSearchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			self.labelSearchBar.topAnchor.constraint(equalTo: self.textSearchBar.bottomAnchor),
		])
		labelSearchBar.enablesReturnKeyAutomatically = false
		labelSearchBar.delegate = self

		propertySearchBar.translatesAutoresizingMaskIntoConstraints = false
		propertySearchBar.placeholder = "key:value,key1:value1"
		NSLayoutConstraint.activate([
			self.propertySearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			self.propertySearchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			self.propertySearchBar.topAnchor.constraint(equalTo: self.labelSearchBar.bottomAnchor),
		])
		propertySearchBar.enablesReturnKeyAutomatically = false
		propertySearchBar.delegate = self
    }

    internal func layoutTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.propertySearchBar.bottomAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

	private func executeQuery(searchTerm: String?, label: String?, property: String?) {
        self.showActivityIndicatorView()
        var query = GroupsQuery.find(searchTerm ?? "")
		if let searchLabel = label {
			query = query.withLabels(searchLabel.components(separatedBy: ","))
		}
		if let searchProperties = property {
			var propertyDictionary: [String: String] = [:]
			let dictElements = searchProperties.components(separatedBy: ",")
			dictElements.forEach {
				let components = $0.components(separatedBy: ":")
				if let key = components.first, let value = components.last {
					propertyDictionary[key] = value
				}
			}
			if !propertyDictionary.isEmpty {
				query = query.withProperties(propertyDictionary)
			}
		}
		query = query.onlyTrending(self.showOnlyTrending)
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

extension GroupsViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		self.executeQuery(searchTerm: self.textSearchBar.text, label: self.labelSearchBar.text, property: self.propertySearchBar.text)
    }
}

extension GroupsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 225
    }
}

extension GroupsViewController: UITableViewDataSource {
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

extension GroupsViewController: GroupTableViewCellDelegate {

	func onShowAction(_ groupId: String, isFollowed: Bool) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
        
        if let group = self.viewModel.findGroup(groupId) {
            let role = group.membership?.role
            let status = group.membership?.status
            actionSheet.addAction(UIAlertAction.init(title: "Details", style: .default, handler: { _ in
                self.showAlert(withText: group.description)
            }))
            if !group.settings.isPrivate || status == .member {
                actionSheet.addAction(UIAlertAction.init(title: "Feed UI", style: .default, handler: { _ in
					self.delegate?.onShowFeed(groupId, byCurrentUser: false)
                }))
				actionSheet.addAction(UIAlertAction.init(title: "Activities", style: .default, handler: { _ in
					self.delegate?.onShowPlainFeed(groupId)
				}))
				actionSheet.addAction(UIAlertAction.init(title: "Activities with Polls", style: .default, handler: { _ in
					self.delegate?.onShowPolls(groupId)
				}))
				actionSheet.addAction(UIAlertAction.init(title: "Announcements with Polls", style: .default, handler: { _ in
					self.delegate?.onShowAnnouncementsPolls(groupId)
				}))
				actionSheet.addAction(UIAlertAction.init(title: "Activities created by Me", style: .default, handler: { _ in
					self.delegate?.onShowFeed(groupId, byCurrentUser: true)
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
					if group.settings.isActionAllowed(action: .post) {
						actionSheet.addAction(UIAlertAction.init(title: "Create Poll", style: .default, handler: { _ in
							self.delegate?.onCreatePoll(groupId)
						}))
					}
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
            if group.membership == nil {
                actionSheet.addAction(UIAlertAction.init(title: "Join", style: .default, handler: { _ in
                    self.viewModel.joinGroup(groupId)
                }))
            }
            if group.membership != nil && group.membership?.role != .owner {
                actionSheet.addAction(UIAlertAction.init(title: "Leave", style: .default, handler: { _ in
                    self.showActivityIndicatorView()
                    self.viewModel.leaveGroup(groupId)
                }))
            }
            if group.membership?.status == .invitationPending {
                actionSheet.addAction(UIAlertAction.init(title: "Approve invitation", style: .default, handler: { _ in
                    self.showActivityIndicatorView()
                    self.viewModel.acceptInvite(groupId, membership: group.membership!)
                }))
            }
        }
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
        
    }
}
