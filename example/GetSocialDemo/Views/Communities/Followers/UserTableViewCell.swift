//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol UserTableViewCellDelegate {
    func onShowActions(_ id: String, isFollowed: Bool, isFriend: Bool, followersCount: Int)
}

class UserTableViewCell: UITableViewCell {

    internal var internalUserId: String?
    internal var isFriend = false
    internal var isFollowed = false
    internal var followersCount: Int = 0

    var delegate: UserTableViewCellDelegate?

    var displayName = UILabel.init()
    var userFollowers = UILabel.init()
    var actionButton = UIButton.init(type: .roundedRect)

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUIElements()
    }

    func update(user: User, isFriend: Bool, isFollowed: Bool, followersCount: Int) {
        self.internalUserId = user.userId
        self.isFriend = isFriend
        self.isFollowed = isFollowed
        self.followersCount = followersCount

        self.userFollowers.text = "\(followersCount) follower\(followersCount > 0 ? "s" : "")"
        self.userFollowers.isUserInteractionEnabled = true

        self.displayName.text = user.displayName
        self.actionButton.setTitle("Actions", for: .normal)
    }
    
    func update(user: User) {
        self.internalUserId = user.userId

        self.userFollowers.isHidden = true

        self.displayName.text = user.displayName
        self.actionButton.setTitle("Actions", for: .normal)
    }

    @objc
    func showActions(sender: Any?) {
        self.delegate?.onShowActions(self.internalUserId!, isFollowed: self.isFollowed, isFriend: self.isFriend, followersCount: self.followersCount)
    }

    func setupUIElements() {
        self.displayName.translatesAutoresizingMaskIntoConstraints = false
        self.displayName.font = self.displayName.font.withSize(14)
        self.contentView.addSubview(self.displayName)

        let displayNameConstraints = [
            self.displayName.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.displayName.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(displayNameConstraints)

        self.userFollowers.translatesAutoresizingMaskIntoConstraints = false
        self.userFollowers.font = self.userFollowers.font.withSize(18)
        self.contentView.addSubview(self.userFollowers)

        let userFollowersConstraints = [
            self.userFollowers.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.userFollowers.topAnchor.constraint(equalTo: self.displayName.bottomAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(userFollowersConstraints)

        self.actionButton.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)
        self.actionButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        self.actionButton.setTitleColor(.black, for: .normal)
        self.actionButton.backgroundColor = .lightGray
        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.actionButton)

        let actionButtonConstraints = [
            self.actionButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0),
            self.actionButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        ]
        NSLayoutConstraint.activate(actionButtonConstraints)
    }
}
