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
    var groupId: String?
    var currentUserRole: Role?

    required init(_ model: GroupMembersModel) {
        self.model = model
        self.tableView = UITableView()
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

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        let top = tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let left = tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let right = tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([left, top, right, bottom])
    }

    private func setup() {
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

        self.view.addSubview(self.tableView)
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
        self.model.onError = { [weak self] error in
            self?.hideActivityIndicatorView()
            self?.showAlert(withText: error.localizedDescription)
        }
    }
    
    private func executeQuery() {
        self.showActivityIndicatorView()
        self.model.loadMembers(MembersQuery.ofGroup(self.groupId!))
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
                if groupMember.membership.status == .approvalPending {
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
