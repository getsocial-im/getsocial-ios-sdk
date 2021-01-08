//
//  CreateGroupsViewController.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 09/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

class AddGroupMemberViewController: UIViewController {
    
    var onGroupMemberAdded: (() -> Void)?
    var model: AddGroupMemberModel
    
    private let scrollView = UIScrollView()

    private let userIdLabel = UILabel()
    private let userIdText = UITextFieldWithCopyPaste()
    
    private let providerIdLabel = UILabel()
    private let providerIdText = UITextFieldWithCopyPaste()

    private let roleLabel = UILabel()
    private let roleSegmentedControl = UISegmentedControl()

    private let statusLabel = UILabel()
    private let statusSegmentedControl = UISegmentedControl()

    private let addButton = UIButton(type: .roundedRect)

    required init(_ groupId: String) {
        self.model = AddGroupMemberModel(groupId: groupId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setup()
        setupModel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupModel() {
        self.model.onMemberAdded = { [weak self] in
            self?.hideActivityIndicatorView()
            self?.onGroupMemberAdded?()
            self?.dismiss(animated: true, completion: {
                self?.showAlert(withText: "Member was added")
            })
        }
        self.model.onError = { [weak self] error in
            self?.hideActivityIndicatorView()
            self?.showAlert(withTitle: "Error", andText: "Failed to add member, error: \(error)")
        }
    }
    
    private func setup() {
        // setup keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        self.view.backgroundColor = UIDesign.Colors.viewBackground
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height + 300)
        self.view.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        setupUserIdRow()
        setupProviderIdRow()
        setupRoleRow()
        setupStatusRow()
        setupAddButton()
    }
    
    private func setupUserIdRow() {
        self.userIdLabel.translatesAutoresizingMaskIntoConstraints = false
        self.userIdLabel.text = "User ID"
        self.userIdLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.userIdLabel)
        
        NSLayoutConstraint.activate([
            self.userIdLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.userIdLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.userIdLabel.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 8),
            self.userIdLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.userIdText.translatesAutoresizingMaskIntoConstraints = false
        self.userIdText.borderStyle = .roundedRect
        self.userIdText.isEnabled = true
        self.scrollView.addSubview(self.userIdText)
        NSLayoutConstraint.activate([
            self.userIdText.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.userIdText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.userIdText.topAnchor.constraint(equalTo: self.userIdLabel.bottomAnchor, constant: 4),
            self.userIdText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupProviderIdRow() {
        self.providerIdLabel.translatesAutoresizingMaskIntoConstraints = false
        self.providerIdLabel.text = "Provider ID"
        self.providerIdLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.providerIdLabel)
        
        NSLayoutConstraint.activate([
            self.providerIdLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.providerIdLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.providerIdLabel.topAnchor.constraint(equalTo: self.userIdText.bottomAnchor, constant: 8),
            self.providerIdLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.providerIdText.translatesAutoresizingMaskIntoConstraints = false
        self.providerIdText.borderStyle = .roundedRect
        self.scrollView.addSubview(self.providerIdText)
        NSLayoutConstraint.activate([
            self.providerIdText.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.providerIdText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.providerIdText.topAnchor.constraint(equalTo: self.providerIdLabel.bottomAnchor, constant: 4),
            self.providerIdText.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupRoleRow() {
        self.roleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.roleLabel.text = "Role"
        self.roleLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.roleLabel)
        
        NSLayoutConstraint.activate([
            self.roleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.roleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.roleLabel.topAnchor.constraint(equalTo: self.providerIdText.bottomAnchor, constant: 8),
            self.roleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.roleSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.roleSegmentedControl.insertSegment(withTitle: "Admin", at: 0, animated: false)
        self.roleSegmentedControl.insertSegment(withTitle: "Member", at: 1, animated: false)
        self.roleSegmentedControl.selectedSegmentIndex = 0
        self.view.addSubview(self.roleSegmentedControl)
        
        NSLayoutConstraint.activate([
            self.roleSegmentedControl.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.roleSegmentedControl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.roleSegmentedControl.topAnchor.constraint(equalTo: self.roleLabel.bottomAnchor, constant: 8),
            self.roleSegmentedControl.heightAnchor.constraint(equalToConstant: 20)
        ])

    }

    private func setupStatusRow() {
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.text = "Status"
        self.statusLabel.textColor = UIDesign.Colors.label
        self.scrollView.addSubview(self.statusLabel)
        
        NSLayoutConstraint.activate([
            self.statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.statusLabel.topAnchor.constraint(equalTo: self.roleSegmentedControl.bottomAnchor, constant: 8),
            self.statusLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.statusSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.statusSegmentedControl.insertSegment(withTitle: "Invite", at: 0, animated: false)
        self.statusSegmentedControl.insertSegment(withTitle: "Member", at: 1, animated: false)
        self.statusSegmentedControl.selectedSegmentIndex = 0
        self.scrollView.addSubview(self.statusSegmentedControl)
        
        NSLayoutConstraint.activate([
            self.statusSegmentedControl.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.statusSegmentedControl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.statusSegmentedControl.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 8),
            self.statusSegmentedControl.heightAnchor.constraint(equalToConstant: 20)
        ])

    }

    private func setupAddButton() {
        self.addButton.translatesAutoresizingMaskIntoConstraints = false
        self.addButton.setTitle("Add", for: .normal)
        self.addButton.addTarget(self, action: #selector(executeAdd(sender:)), for: .touchUpInside)
        self.scrollView.addSubview(self.addButton)
        
        NSLayoutConstraint.activate([
            self.addButton.topAnchor.constraint(equalTo: self.statusSegmentedControl.bottomAnchor, constant: 8),
            self.addButton.heightAnchor.constraint(equalToConstant: 40),
            self.addButton.widthAnchor.constraint(equalToConstant: 100),
            self.addButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.addButton.bottomAnchor.constraint(greaterThanOrEqualTo: self.scrollView.bottomAnchor, constant: -8)
        ])
    }
    
    @objc
    private func executeAdd(sender: UIView) {
        guard let userId = self.userIdText.text else {
            self.showAlert(withText: "UserId cannot be empty")
            return
        }
        let status = self.statusSegmentedControl.selectedSegmentIndex == 0 ? MemberStatus.invitationPending : MemberStatus.member
        let role = self.roleSegmentedControl.selectedSegmentIndex == 0 ? Role.admin : Role.member
        self.showActivityIndicatorView()
        self.model.addMember(userId: userId,
                             providerId: self.providerIdText.text,
                             role: role,
                             status: status)
    }
    
    // MARK: Handle keyboard
    
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let keyboardSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.scrollView.contentInset = UIEdgeInsets.init(top: self.scrollView.contentInset.top, left: self.scrollView.contentInset.left, bottom: keyboardSize.height, right: self.scrollView.contentInset.right)
        }
    }

    @objc
    private func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset = UIEdgeInsets.init(top: self.scrollView.contentInset.top, left: self.scrollView.contentInset.left, bottom: 0, right: self.scrollView.contentInset.right)
    }

}
