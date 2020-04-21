//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol TopicTableViewCellDelegate {
    func onFollowersClicked(ofTopic: String)
    func onFollowButtonClicked(ofTopic: String)
    func onTopicClicked(_ id: String)
    func onShowFeedClicked(_ id: String)
    func onPostActivityClicked(_ id: String)
}

class TopicTableViewCell: UITableViewCell {

    static var dateFormatter: DateFormatter?
    var internalTopicId: String?
    var canPost: Bool = false

    var topicTitle: UILabel = UILabel()
    var topicDescription: UILabel = UILabel()
    var topicCreatedAt: UILabel = UILabel()
    var topicUpdatedAt: UILabel = UILabel()
    var topicFollowers: UILabel = UILabel()
    var followButton: UIButton = UIButton.init(type: .roundedRect)
    var feedButton: UIButton = UIButton.init(type: .roundedRect)
    var postButton: UIButton = UIButton.init(type: .roundedRect)

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
        self.canPost = topic.settings.isActionAllowed(action: .postActivity)

        self.topicTitle.text = "Title: \(topic.title ?? "")"
        self.topicDescription.text = "Description: \(topic.topicDescription ?? "")"
        let createdAtDate = Date.init(timeIntervalSince1970: TimeInterval(topic.createdAt))
        let updatedAtDate = Date.init(timeIntervalSince1970: TimeInterval(topic.updatedAt))
        self.topicCreatedAt.text = "Created: \(TopicTableViewCell.dateFormatter?.string(from: createdAtDate) ?? "")"
        self.topicUpdatedAt.text = "Updated: \(TopicTableViewCell.dateFormatter?.string(from: updatedAtDate) ?? "")"

        self.topicFollowers.text = "\(topic.followersCount) follower\(topic.followersCount > 1 ? "s" : "")"
        self.topicFollowers.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(showFollowers(sender:)))
        gestureRecognizer.delegate = self
        self.topicFollowers.addGestureRecognizer(gestureRecognizer)

        self.followButton.setTitle(topic.isFollowedByMe ? "Unfollow" : "Follow", for: .normal)
        self.followButton.addTarget(self, action: #selector(follow(sender:)), for: .touchUpInside)

        self.feedButton.setTitle("Feed", for: .normal)
        self.feedButton.addTarget(self, action: #selector(showFeed(sender:)), for: .touchUpInside)

        self.postButton.setTitle("Post", for: .normal)
        self.postButton.addTarget(self, action: #selector(postActivity(sender:)), for: .touchUpInside)

        self.postButton.isHidden = !self.canPost

    }

    @objc
    func postActivity(sender: Any?) {
        self.delegate?.onPostActivityClicked(self.internalTopicId!)
    }

    @objc
    func showFeed(sender: Any?) {
        self.delegate?.onShowFeedClicked(self.internalTopicId!)
    }

    @objc
    func follow(sender: Any?) {
        self.delegate?.onFollowButtonClicked(ofTopic: self.internalTopicId!)
    }

    @objc
    func showFollowers(sender: Any?) {
        self.delegate?.onFollowersClicked(ofTopic: self.internalTopicId!)
    }

    @objc
    func showDetails(sender: Any?) {
        self.delegate?.onTopicClicked(self.internalTopicId!)
    }

    private func addUIElements() {
        self.contentView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(showDetails(sender:))))

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

        self.topicFollowers.translatesAutoresizingMaskIntoConstraints = false
        self.topicFollowers.font = self.topicFollowers.font.withSize(18)
        self.contentView.addSubview(self.topicFollowers)

        let topicFollowersConstraints = [
            self.topicFollowers.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.topicFollowers.topAnchor.constraint(equalTo: self.topicUpdatedAt.bottomAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(topicFollowersConstraints)

        self.followButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        self.followButton.setTitleColor(.black, for: .normal)
        self.followButton.backgroundColor = .lightGray
        self.followButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.followButton)

        let followButtonConstraints = [
            self.followButton.leadingAnchor.constraint(equalTo: self.topicFollowers.trailingAnchor, constant: 8),
            self.followButton.topAnchor.constraint(equalTo: self.topicUpdatedAt.bottomAnchor, constant: 0)
        ]
        NSLayoutConstraint.activate(followButtonConstraints)

        self.feedButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        self.feedButton.setTitleColor(.black, for: .normal)
        self.feedButton.backgroundColor = .lightGray
        self.feedButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.feedButton)

        let feedButtonConstraints = [
            self.feedButton.topAnchor.constraint(equalTo: self.topicUpdatedAt.bottomAnchor, constant: 0),
            self.feedButton.leadingAnchor.constraint(equalTo: self.followButton.trailingAnchor, constant: 8),
        ]

        self.postButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        self.postButton.setTitleColor(.black, for: .normal)
        self.postButton.backgroundColor = .lightGray
        self.postButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.postButton)

        let postButtonConstraints = [
            self.postButton.topAnchor.constraint(equalTo: self.topicUpdatedAt.bottomAnchor, constant: 0),
            self.postButton.leadingAnchor.constraint(equalTo: self.feedButton.trailingAnchor, constant: 8),
            self.postButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        ]
        NSLayoutConstraint.activate(feedButtonConstraints)
        NSLayoutConstraint.activate(postButtonConstraints)
    }
}
