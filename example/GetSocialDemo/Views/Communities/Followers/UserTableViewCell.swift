//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol UserTableViewCellDelegate {
    func onUserClicked(_ id: String)
    func onFriendButtonClicked(_ id: String, isFriend: Bool)
}

class UserTableViewCell: UITableViewCell {

    internal var internalUserId: String?
    internal var isFriend = false

    var delegate: UserTableViewCellDelegate?

    var friendButton = UIButton.init(type: .roundedRect)

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUIElements()
    }

    func update(user: User, isFriend: Bool) {
        self.internalUserId = user.userId
        self.isFriend = isFriend
        self.textLabel?.text = user.displayName

        self.friendButton.setTitle(self.isFriend ? "Remove Friend" : "Add Friend", for: .normal)
    }

    @objc
    func showDetails(sender: Any) {
        self.delegate?.onUserClicked(self.internalUserId!)
    }

    @objc
    func updateFriendStatus(sender: Any?) {
        self.delegate?.onFriendButtonClicked(self.internalUserId!, isFriend: self.isFriend)
    }

    func setupUIElements() {
        self.contentView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(showDetails(sender:))))

        self.friendButton.addTarget(self, action: #selector(updateFriendStatus(sender:)), for: .touchUpInside)

        self.friendButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        self.friendButton.setTitleColor(.black, for: .normal)
        self.friendButton.backgroundColor = .lightGray
        self.friendButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.friendButton)

        let friendButtonConstraints = [
            self.friendButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0),
            self.friendButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        ]
        NSLayoutConstraint.activate(friendButtonConstraints)
    }
}
