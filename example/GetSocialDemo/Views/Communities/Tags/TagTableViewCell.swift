//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol TagTableViewCellDelegate {
	func onShowActions(_ tag: Tag, isFollowed: Bool)
}

class TagTableViewCell: UITableViewCell {

    internal var hashtag: Tag?
	var isFollowed: Bool = false

    var delegate: TagTableViewCellDelegate?

    var displayName = UILabel.init()
	var tagScore: UILabel = UILabel()
	var tagActivitiesCount: UILabel = UILabel()
	var tagFollowers: UILabel = UILabel()
    var actionButton = UIButton.init(type: .roundedRect)

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUIElements()
    }

    func update(tag: Tag) {
        self.hashtag = tag
        self.displayName.text = tag.name
		self.isFollowed = tag.isFollowedByMe
		self.tagFollowers.text = "\(tag.followersCount) follower\(tag.followersCount > 1 ? "s" : "")"
		self.tagScore.text = "Popularity: \(tag.popularity)"
		self.tagActivitiesCount.text = "Activities count: \(tag.activitiesCount)"
        self.actionButton.setTitle("Actions", for: .normal)
    }

    @objc
    func showActions(sender: Any?) {
		self.delegate?.onShowActions(self.hashtag!, isFollowed: self.isFollowed)
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

		self.tagScore.translatesAutoresizingMaskIntoConstraints = false
		self.tagScore.font = self.tagScore.font.withSize(14)
		self.contentView.addSubview(self.tagScore)

		let tagScoreConstraints = [
			self.tagScore.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.tagScore.topAnchor.constraint(equalTo: self.displayName.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(tagScoreConstraints)

		self.tagActivitiesCount.translatesAutoresizingMaskIntoConstraints = false
		self.tagActivitiesCount.font = self.tagActivitiesCount.font.withSize(14)
		self.contentView.addSubview(self.tagActivitiesCount)

		let tagActivitiesCountConstraints = [
			self.tagActivitiesCount.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.tagActivitiesCount.topAnchor.constraint(equalTo: self.tagScore.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(tagActivitiesCountConstraints)

		self.tagFollowers.translatesAutoresizingMaskIntoConstraints = false
		self.tagFollowers.font = self.tagFollowers.font.withSize(14)
		self.contentView.addSubview(self.tagFollowers)

		let tagFollowersConstraints = [
			self.tagFollowers.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.tagFollowers.topAnchor.constraint(equalTo: self.tagActivitiesCount.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(tagFollowersConstraints)

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
