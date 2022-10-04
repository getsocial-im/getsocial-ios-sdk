//
//  GroupMemberViewCell.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 09/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit

protocol GroupMemberViewCellDelegate {
    func onShowActions(_ memberId: String)
}

class GroupMemberViewCell: UITableViewCell {

    var delegate: GroupMemberViewCellDelegate?
    
    private let memberNameLabel = UILabel()
    private let membershipStatusLabel = UILabel()
    private let membershipRoleLabel = UILabel()
    private let actionsButton = UIButton.init(type: .roundedRect)
    private var memberId: String?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    func updateContent(_ member: GroupMember) {
        self.memberId = member.userId
        self.memberNameLabel.text = member.displayName
        var status = ""
        switch member.membership.status {
        case .approvalPending:
            status = "APPROVAL_PENDING"
            break
        case .invitationPending:
            status = "INVITATION_PENDING"
            break
        case .rejected:
                status = "REJECTED"
                break
        default:
            status = "APPROVED"
            break
        }
        self.membershipStatusLabel.text = "Status: \(status)"
        self.membershipRoleLabel.text = "Role: \(member.membership.role.description)"
    }

    private func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupMemberNameLabel()
        self.setupMembershipStatusLabel()
        self.setupMembershipRoleLabel()
        self.setupActionButton()
    }
    
    private func setupMemberNameLabel() {
        self.memberNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.memberNameLabel)
        
        NSLayoutConstraint.activate([
            self.memberNameLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.memberNameLabel.widthAnchor.constraint(equalToConstant: 200),
            self.memberNameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8)
        ])
    }

    private func setupMembershipStatusLabel() {
        self.membershipStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.membershipStatusLabel)

        NSLayoutConstraint.activate([
            self.membershipStatusLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.membershipStatusLabel.widthAnchor.constraint(equalToConstant: 200),
            self.membershipStatusLabel.topAnchor.constraint(equalTo: self.memberNameLabel.bottomAnchor, constant: 8)
        ])
    }

    private func setupMembershipRoleLabel() {
        self.membershipRoleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.membershipRoleLabel)

        NSLayoutConstraint.activate([
            self.membershipRoleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.membershipRoleLabel.widthAnchor.constraint(equalToConstant: 200),
            self.membershipRoleLabel.topAnchor.constraint(equalTo: self.membershipStatusLabel.bottomAnchor, constant: 8)
        ])
    }
    
    private func setupActionButton() {
        self.actionsButton.translatesAutoresizingMaskIntoConstraints = false
        self.actionsButton.setTitle("Actions", for: .normal)
        self.actionsButton.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)
        self.contentView.addSubview(self.actionsButton)

        NSLayoutConstraint.activate([
            self.actionsButton.widthAnchor.constraint(equalToConstant: 100),
            self.actionsButton.heightAnchor.constraint(equalToConstant: 30),
            self.actionsButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.actionsButton.leadingAnchor.constraint(equalTo: self.memberNameLabel.trailingAnchor, constant:
                8),
            self.actionsButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        ])
    }
    
    @objc
    private func showActions(sender: UIView) {
        self.delegate?.onShowActions(self.memberId!)
    }

}
