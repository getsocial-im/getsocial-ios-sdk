//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol LabelTableViewCellDelegate {
	func onShowActions(_ label: Label, isFollowed: Bool)
}

class LabelTableViewCell: UITableViewCell {

    internal var label: Label?
	var isFollowed: Bool = false

    var delegate: LabelTableViewCellDelegate?

    var displayName = UILabel.init()
	var labelScore: UILabel = UILabel()
	var labelActivitiesCount: UILabel = UILabel()
	var labelFollowers: UILabel = UILabel()
    var actionButton = UIButton.init(type: .roundedRect)

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUIElements()
    }

    func update(label: Label) {
        self.label = label
        self.displayName.text = label.name
		self.isFollowed = label.isFollowedByMe
		self.labelFollowers.text = "\(label.followersCount) follower\(label.followersCount > 1 ? "s" : "")"
		self.labelScore.text = "Popularity: \(label.popularity)"
		self.labelActivitiesCount.text = "Activities count: \(label.activitiesCount)"
        self.actionButton.setTitle("Actions", for: .normal)
    }

    @objc
    func showActions(sender: Any?) {
		self.delegate?.onShowActions(self.label!, isFollowed: self.isFollowed)
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

		self.labelScore.translatesAutoresizingMaskIntoConstraints = false
		self.labelScore.font = self.labelScore.font.withSize(14)
		self.contentView.addSubview(self.labelScore)

		let labelScoreConstraints = [
			self.labelScore.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.labelScore.topAnchor.constraint(equalTo: self.displayName.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(labelScoreConstraints)

		self.labelActivitiesCount.translatesAutoresizingMaskIntoConstraints = false
		self.labelActivitiesCount.font = self.labelActivitiesCount.font.withSize(14)
		self.contentView.addSubview(self.labelActivitiesCount)

		let labelActivitiesCountConstraints = [
			self.labelActivitiesCount.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.labelActivitiesCount.topAnchor.constraint(equalTo: self.labelScore.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(labelActivitiesCountConstraints)

		self.labelFollowers.translatesAutoresizingMaskIntoConstraints = false
		self.labelFollowers.font = self.labelFollowers.font.withSize(14)
		self.contentView.addSubview(self.labelFollowers)

		let labelFollowersConstraints = [
			self.labelFollowers.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.labelFollowers.topAnchor.constraint(equalTo: self.labelActivitiesCount.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(labelFollowersConstraints)

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
