//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol TagTableViewCellDelegate {
    func onShowActions(_ tag: String)
}

class TagTableViewCell: UITableViewCell {

    internal var hashtag: String?

    var delegate: TagTableViewCellDelegate?

    var displayName = UILabel.init()
    var actionButton = UIButton.init(type: .roundedRect)

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUIElements()
    }

    func update(tag: String) {
        self.hashtag = tag
        self.displayName.text = tag
        self.actionButton.setTitle("Actions", for: .normal)
    }

    @objc
    func showActions(sender: Any?) {
        self.delegate?.onShowActions(self.hashtag!)
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
