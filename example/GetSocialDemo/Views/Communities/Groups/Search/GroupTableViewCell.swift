//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol GroupTableViewCellDelegate {
    func onShowAction(_ groupId: String, isFollowed: Bool)
}

class GroupTableViewCell: UITableViewCell {

    static var dateFormatter: DateFormatter?
    var groupId: String?

    var groupTitle: UILabel = UILabel()
    var groupDescription: UILabel = UILabel()
    var groupCreatedAt: UILabel = UILabel()
    var groupUpdatedAt: UILabel = UILabel()
	var groupScore: UILabel = UILabel()
	var groupLabels: UILabel = UILabel()
	var groupProperties: UILabel = UILabel()
    var memberStatus: UILabel = UILabel()
    var memberRole: UILabel = UILabel()
    var actionButton: UIButton = UIButton.init(type: .roundedRect)
	var isFollowed: Bool = false

    var delegate: GroupTableViewCellDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if GroupTableViewCell.dateFormatter == nil {
            GroupTableViewCell.dateFormatter = DateFormatter()
            GroupTableViewCell.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        addUIElements()
    }

    func update(group: Group) {
        self.groupId = group.id

        self.groupTitle.text = "Title: \(group.title ?? "")"
        self.groupDescription.text = "Description: \(group.groupDescription ?? "")"
        let createdAtDate = Date.init(timeIntervalSince1970: TimeInterval(group.createdAt))
        let updatedAtDate = Date.init(timeIntervalSince1970: TimeInterval(group.updatedAt))
        self.groupCreatedAt.text = "Created: \(GroupTableViewCell.dateFormatter?.string(from: createdAtDate) ?? "")"
        self.groupUpdatedAt.text = "Updated: \(GroupTableViewCell.dateFormatter?.string(from: updatedAtDate) ?? "")"
		self.groupScore.text = "Popularity: \(group.popularity)"
		self.groupLabels.text = "Labels: \(group.settings.labels.joined(separator: ","))"
		self.groupProperties.text = "Properties: \(group.settings.properties.map { "\($0)=\($1)" }.joined(separator: ","))"
        var status = ""
        switch group.membership?.status {
        case .approvalPending:
            status = "APPROVAL_PENDING"
            break
        case .invitationPending:
            status = "INVITATION_PENDING"
            break
        case .member:
            status = "APPROVED"
            break
        case .rejected:
            status = "REJECTED"
            break
        default:
            status = "UNKNOWN"
            break
        }
        self.memberStatus.text = "Member status: \(status)"
        var role = ""
        switch group.membership?.role {
        case .owner:
            role = "OWNER"
            break
        case .admin:
            role = "ADMIN"
            break
        case .member:
            role = "MEMBER"
            break
        default:
            role = "UNKNOWN"
            break
        }
        self.memberRole.text = "Member role: \(role)"
		self.isFollowed = group.isFollowedByMe

    }

    @objc
    func showActions(sender: Any?) {
		self.delegate?.onShowAction(self.groupId!, isFollowed: self.isFollowed)
    }

    private func addUIElements() {
        self.groupTitle.translatesAutoresizingMaskIntoConstraints = false
        self.groupTitle.font = self.groupTitle.font.withSize(14)
        self.contentView.addSubview(self.groupTitle)
        NSLayoutConstraint.activate([
            self.groupTitle.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.groupTitle.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            self.groupTitle.widthAnchor.constraint(equalToConstant: 200),
            self.groupTitle.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.groupDescription.translatesAutoresizingMaskIntoConstraints = false
        self.groupDescription.font = self.groupDescription.font.withSize(14)
        self.contentView.addSubview(self.groupDescription)
        NSLayoutConstraint.activate([
            self.groupDescription.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.groupDescription.topAnchor.constraint(equalTo: self.groupTitle.bottomAnchor, constant: 4),
            self.groupDescription.widthAnchor.constraint(equalToConstant: 200),
            self.groupDescription.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.groupCreatedAt.translatesAutoresizingMaskIntoConstraints = false
        self.groupCreatedAt.font = self.groupCreatedAt.font.withSize(14)
        self.contentView.addSubview(self.groupCreatedAt)
        NSLayoutConstraint.activate([
            self.groupCreatedAt.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.groupCreatedAt.topAnchor.constraint(equalTo: self.groupDescription.bottomAnchor, constant: 4),
            self.groupCreatedAt.widthAnchor.constraint(equalToConstant: 200),
            self.groupCreatedAt.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.groupUpdatedAt.translatesAutoresizingMaskIntoConstraints = false
        self.groupUpdatedAt.font = self.groupUpdatedAt.font.withSize(14)
        self.contentView.addSubview(self.groupUpdatedAt)
        NSLayoutConstraint.activate([
            self.groupUpdatedAt.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.groupUpdatedAt.topAnchor.constraint(equalTo: self.groupCreatedAt.bottomAnchor, constant: 4),
            self.groupUpdatedAt.widthAnchor.constraint(equalToConstant: 200),
            self.groupUpdatedAt.heightAnchor.constraint(equalToConstant: 20)
        ])

		self.groupScore.translatesAutoresizingMaskIntoConstraints = false
		self.groupScore.font = self.groupScore.font.withSize(14)
		self.contentView.addSubview(self.groupScore)
		NSLayoutConstraint.activate([
			self.groupScore.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.groupScore.topAnchor.constraint(equalTo: self.groupUpdatedAt.bottomAnchor, constant: 4),
			self.groupScore.widthAnchor.constraint(equalToConstant: 200),
			self.groupScore.heightAnchor.constraint(equalToConstant: 20)
		])

		self.groupLabels.translatesAutoresizingMaskIntoConstraints = false
		self.groupLabels.font = self.groupLabels.font.withSize(14)
		self.contentView.addSubview(self.groupLabels)
		NSLayoutConstraint.activate([
			self.groupLabels.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.groupLabels.topAnchor.constraint(equalTo: self.groupScore.bottomAnchor, constant: 4),
			self.groupLabels.widthAnchor.constraint(equalToConstant: 200),
			self.groupLabels.heightAnchor.constraint(equalToConstant: 20)
		])

		self.groupProperties.translatesAutoresizingMaskIntoConstraints = false
		self.groupProperties.font = self.groupProperties.font.withSize(14)
		self.contentView.addSubview(self.groupProperties)
		NSLayoutConstraint.activate([
			self.groupProperties.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.groupProperties.topAnchor.constraint(equalTo: self.groupLabels.bottomAnchor, constant: 4),
			self.groupProperties.widthAnchor.constraint(equalToConstant: 200),
			self.groupProperties.heightAnchor.constraint(equalToConstant: 20)
		])

        self.memberStatus.translatesAutoresizingMaskIntoConstraints = false
        self.memberStatus.font = self.memberStatus.font.withSize(14)
        self.contentView.addSubview(self.memberStatus)
        NSLayoutConstraint.activate([
            self.memberStatus.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.memberStatus.topAnchor.constraint(equalTo: self.groupProperties.bottomAnchor, constant: 4),
            self.memberStatus.widthAnchor.constraint(equalToConstant: 200),
            self.memberStatus.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.memberRole.translatesAutoresizingMaskIntoConstraints = false
        self.memberRole.font = self.memberStatus.font.withSize(14)
        self.contentView.addSubview(self.memberRole)
        NSLayoutConstraint.activate([
            self.memberRole.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.memberRole.topAnchor.constraint(equalTo: self.memberStatus.bottomAnchor, constant: 4),
            self.memberRole.widthAnchor.constraint(equalToConstant: 200),
            self.memberRole.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.actionButton.setTitle("Actions", for: .normal)
        self.actionButton.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)
        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.actionButton)

        NSLayoutConstraint.activate([
            self.actionButton.leadingAnchor.constraint(equalTo: self.groupTitle.trailingAnchor, constant: 8),
            self.actionButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 8),
            self.actionButton.heightAnchor.constraint(equalToConstant: 30),
            self.actionButton.widthAnchor.constraint(equalToConstant: 100),
            self.actionButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        ])
    }
}
