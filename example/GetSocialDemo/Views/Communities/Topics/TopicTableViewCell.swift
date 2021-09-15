//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol TopicTableViewCellDelegate {
    func onShowActions(_ ofTopic: String, isFollowed: Bool, canPost: Bool)
}

class TopicTableViewCell: UITableViewCell {

    static var dateFormatter: DateFormatter?
    var internalTopicId: String?
    var canPost: Bool = false
    var isFollowed: Bool = false

    var topicTitle: UILabel = UILabel()
    var topicDescription: UILabel = UILabel()
    var topicCreatedAt: UILabel = UILabel()
    var topicUpdatedAt: UILabel = UILabel()
    var topicFollowers: UILabel = UILabel()
	var topicScore: UILabel = UILabel()
    var actionButton: UIButton = UIButton.init(type: .roundedRect)

    var delegate: TopicTableViewCellDelegate?

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        if TopicTableViewCell.dateFormatter == nil {
            TopicTableViewCell.dateFormatter = DateFormatter()
            TopicTableViewCell.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        addUIElements()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if TopicTableViewCell.dateFormatter == nil {
            TopicTableViewCell.dateFormatter = DateFormatter()
            TopicTableViewCell.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        addUIElements()
    }

    func update(topic: Topic) {
        self.internalTopicId = topic.id
        self.canPost = topic.settings.isActionAllowed(action: .post)
        self.isFollowed = topic.isFollowedByMe

        self.topicTitle.text = "Title: \(topic.title ?? "")"
        self.topicDescription.text = "Description: \(topic.topicDescription ?? "")"
        let createdAtDate = Date.init(timeIntervalSince1970: TimeInterval(topic.createdAt))
        let updatedAtDate = Date.init(timeIntervalSince1970: TimeInterval(topic.updatedAt))
        self.topicCreatedAt.text = "Created: \(TopicTableViewCell.dateFormatter?.string(from: createdAtDate) ?? "")"
        self.topicUpdatedAt.text = "Updated: \(TopicTableViewCell.dateFormatter?.string(from: updatedAtDate) ?? "")"

        self.topicFollowers.text = "\(topic.followersCount) follower\(topic.followersCount > 1 ? "s" : "")"
        self.topicFollowers.isUserInteractionEnabled = true
		self.topicScore.text = "Popularity: \(topic.popularity)"

        self.actionButton.setTitle("Actions", for: .normal)
        self.actionButton.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)


    }

    @objc
    func showActions(sender: Any?) {
        self.delegate?.onShowActions(self.internalTopicId!, isFollowed: self.isFollowed, canPost: self.canPost)
    }

    private func addUIElements() {
        self.topicTitle.translatesAutoresizingMaskIntoConstraints = false
        self.topicTitle.font = self.topicTitle.font.withSize(14)
        self.contentView.addSubview(self.topicTitle)
        let topicTitleConstraints = [
            self.topicTitle.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.topicTitle.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(topicTitleConstraints)

        self.topicDescription.translatesAutoresizingMaskIntoConstraints = false
        self.topicDescription.font = self.topicDescription.font.withSize(14)
        self.contentView.addSubview(self.topicDescription)
        let topicDescriptionConstraints = [
            self.topicDescription.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.topicDescription.topAnchor.constraint(equalTo: self.topicTitle.bottomAnchor, constant: 4)
        ]
        NSLayoutConstraint.activate(topicDescriptionConstraints)

        self.topicCreatedAt.translatesAutoresizingMaskIntoConstraints = false
        self.topicCreatedAt.font = self.topicCreatedAt.font.withSize(14)
        self.contentView.addSubview(self.topicCreatedAt)
        let topicCreatedAtConstraints = [
            self.topicCreatedAt.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.topicCreatedAt.topAnchor.constraint(equalTo: self.topicDescription.bottomAnchor, constant: 4)
        ]
        NSLayoutConstraint.activate(topicCreatedAtConstraints)

        self.topicUpdatedAt.translatesAutoresizingMaskIntoConstraints = false
        self.topicUpdatedAt.font = self.topicUpdatedAt.font.withSize(14)
        self.contentView.addSubview(self.topicUpdatedAt)
        let topicUpdatedAtConstraints = [
            self.topicUpdatedAt.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.topicUpdatedAt.topAnchor.constraint(equalTo: self.topicCreatedAt.bottomAnchor, constant: 4)
        ]
        NSLayoutConstraint.activate(topicUpdatedAtConstraints)

		self.topicScore.translatesAutoresizingMaskIntoConstraints = false
		self.topicScore.font = self.topicScore.font.withSize(14)
		self.contentView.addSubview(self.topicScore)

		let topicScoreConstraints = [
			self.topicScore.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.topicScore.topAnchor.constraint(equalTo: self.topicUpdatedAt.bottomAnchor, constant: 8)
		]
		NSLayoutConstraint.activate(topicScoreConstraints)

        self.topicFollowers.translatesAutoresizingMaskIntoConstraints = false
        self.topicFollowers.font = self.topicFollowers.font.withSize(18)
        self.contentView.addSubview(self.topicFollowers)

        let topicFollowersConstraints = [
            self.topicFollowers.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.topicFollowers.topAnchor.constraint(equalTo: self.topicScore.bottomAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(topicFollowersConstraints)

        self.actionButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        self.actionButton.setTitleColor(.black, for: .normal)
        self.actionButton.backgroundColor = .lightGray
        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.actionButton)

        let followButtonConstraints = [
            self.actionButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),
            self.actionButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ]
        NSLayoutConstraint.activate(followButtonConstraints)
    }
}
