//
//  GroupMembersViewController.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 09/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class GroupMembersViewController: UIViewController {

    private let model: GroupMembersModel
    private let tableView: UITableView
	private let statusControl: UISegmentedControl
    var groupId: String?
    var currentUserRole: Role?
    var memberStatus: MemberStatus?
    
    var textSearchBar: UISearchBar = UISearchBar()

    required init(_ model: GroupMembersModel) {
        self.model = model
        self.tableView = UITableView()
		self.statusControl = UISegmentedControl()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setup()
        setupModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        executeQuery()
    }

    override func viewWillLayoutSubviews() {
        layoutTableView()
    }

    internal func layoutTableView() {
        
        textSearchBar.translatesAutoresizingMaskIntoConstraints = false
        let top = textSearchBar.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? self.view.topAnchor)
        let left = textSearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = textSearchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)

        NSLayoutConstraint.activate([left, top, right])

        textSearchBar.enablesReturnKeyAutomatically = false
        textSearchBar.delegate = self
        textSearchBar.autocapitalizationType = .none
    
		self.statusControl.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			self.statusControl.topAnchor.constraint(equalTo: self.textSearchBar.bottomAnchor),
			self.statusControl.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			self.statusControl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			self.statusControl.heightAnchor.constraint(equalToConstant: 30)
		])

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.statusControl.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        ])
    }

    private func setup() {
		self.view.backgroundColor = UIDesign.Colors.viewBackground
        self.setupTableView()
        if self.currentUserRole == .admin || self.currentUserRole == .owner {
            let addMemberButton = UIBarButtonItem.init(title: "Add", style: .plain, target: self, action: #selector(addGroupMember(sender:)))
            self.navigationItem.rightBarButtonItem = addMemberButton
        }
    }
    
    private func setupTableView() {
        self.tableView.backgroundColor = UIDesign.Colors.viewBackground
        self.tableView.register(GroupMemberViewCell.self, forCellReuseIdentifier: "groupmemberviewcell")
        self.tableView.allowsSelection = false

        self.tableView.dataSource = self
        self.tableView.delegate = self        

		self.statusControl.insertSegment(withTitle: "All", at: 0, animated: false)
		self.statusControl.insertSegment(withTitle: "Approved", at: 1, animated: false)
		self.statusControl.insertSegment(withTitle: "Approval pending", at: 2, animated: false)
		self.statusControl.insertSegment(withTitle: "Invite pending", at: 3, animated: false)
        self.statusControl.insertSegment(withTitle: "Rejected", at: 4, animated: false)
		self.statusControl.selectedSegmentIndex = 0
		self.statusControl.addTarget(self, action: #selector(statusControlValueChanged), for: .valueChanged)

        self.view.addSubview(self.tableView)
		self.view.addSubview(self.statusControl)
        self.view.addSubview(self.textSearchBar)
        
    }
    
    private func setupModel() {
        self.model.onMembersRetrieved = { [weak self] in
            self?.hideActivityIndicatorView()
            self?.tableView.reloadData()
        }
        self.model.onMemberRemoved = { [weak self] in
            self?.hideActivityIndicatorView()
            self?.executeQuery()
            self?.showAlert(withText: "Member removed")
        }
        self.model.onMemberApproved = { [weak self] in
            self?.hideActivityIndicatorView()
            self?.executeQuery()
            self?.showAlert(withText: "Member approved")
        }
        self.model.onMemberRejected = { [weak self] in
            self?.hideActivityIndicatorView()
            self?.executeQuery()
            self?.showAlert(withText: "Member rejected")
        }
        self.model.onError = { [weak self] error in
            self?.hideActivityIndicatorView()
            self?.showAlert(withText: error.localizedDescription)
        }
    }
    
	private func executeQuery() {
        self.showActivityIndicatorView()
		var query = MembersQuery.ofGroup(self.groupId!)
        if let memberStatus = memberStatus {
			query = query.withStatus(memberStatus)
		}
        
        if let name = self.textSearchBar.text {
            query = query.withName(name)
        }
		self.model.loadMembers(query)
    }

	@objc
	func statusControlValueChanged() {
		switch self.statusControl.selectedSegmentIndex {
			case 1:
                memberStatus = .member
			case 2:
                memberStatus = .approvalPending
			case 3:
                memberStatus = .invitationPending
            case 4:
                memberStatus = .rejected
			default:
                memberStatus = nil
		}
        executeQuery()
	}

    @objc
    func addGroupMember(sender: Any) {
        let vc = AddGroupMemberViewController(self.groupId!)
        vc.onGroupMemberAdded = { [weak self] in
            self?.executeQuery()
        }
        self.present(vc, animated: true, completion: nil)
    }
    
}

extension GroupMembersViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.executeQuery()
    }
}


extension GroupMembersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

extension GroupMembersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.groupMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "groupmemberviewcell", for: indexPath) as? GroupMemberViewCell {
            cell.updateContent(self.model.groupMembers[indexPath.row])
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }
}

extension GroupMembersViewController: GroupMemberViewCellDelegate {
    func onShowActions(_ memberId: String) {
        let actionSheet = UIAlertController.init(title: "Available actions", message: nil, preferredStyle: .actionSheet)
        if let groupMember = self.model.findMember(memberId) {
            actionSheet.addAction(UIAlertAction.init(title: "Details", style: .default, handler: { _ in
                self.showAlert(withTitle: "Details", andText: groupMember.description)
            }))
            if (self.currentUserRole == .admin || self.currentUserRole == .owner) && (groupMember.userId != GetSocial.currentUser()?.userId && groupMember.membership.role != .owner) {
                actionSheet.addAction(UIAlertAction.init(title: "Remove", style: .default, handler: { _ in
                    self.showActivityIndicatorView()
                    self.model.removeMember(groupMember, groupId: self.groupId!)
                }))
                if groupMember.membership.status == .approvalPending || groupMember.membership.status == .member {
                    actionSheet.addAction(UIAlertAction.init(title: "Reject", style: .default, handler: { _ in
                        self.showActivityIndicatorView()
                        self.model.rejectMember(groupMember, groupId: self.groupId!)
                    }))
                }
                
                if groupMember.membership.status == .approvalPending || groupMember.membership.status == .rejected {
                    actionSheet.addAction(UIAlertAction.init(title: "Approve", style: .default, handler: { _ in
                        self.showActivityIndicatorView()
                        self.model.approveMember(groupMember, groupId: self.groupId!)
                    }))
                }
            }
            if groupMember.userId == GetSocial.currentUser()?.userId && self.currentUserRole != .owner {
                actionSheet.addAction(UIAlertAction.init(title: "Leave", style: .default, handler: { _ in
                    self.showActivityIndicatorView()
                    self.model.removeMember(groupMember, groupId: self.groupId!)
                }))
            }
        }
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
}
