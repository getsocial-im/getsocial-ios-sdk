//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

class ChatMessageViewCell: UITableViewCell {

    static var dateFormatter: DateFormatter?

    var onShowDetails: (() -> Void)?
    var sender: UILabel = UILabel()
    var messageText: UILabel = UILabel()
    var sentAt: UILabel = UILabel()
    var imageUrl: UILabel = UILabel()
    var videoUrl: UILabel = UILabel()
    var showDetailsBtn: UIButton = UIButton.init(type: .roundedRect)

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if ChatMessageViewCell.dateFormatter == nil {
            ChatMessageViewCell.dateFormatter = DateFormatter()
            ChatMessageViewCell.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        addUIElements()
    }

    func update(_ message: ChatMessage) {
        let currentUserId = GetSocial.currentUser()?.userId
        var senderText = "Sender: \(message.author.displayName)"
        if message.author.userId == currentUserId {
            senderText += " (Current)"
        }
        self.sender.text = senderText
        if let text = message.text {
            self.messageText.text = "Text: \(text)"
        } else {
            self.messageText.text = "Text: "
        }
        let createdAtDate = Date.init(timeIntervalSince1970: TimeInterval(message.sentAt))
        self.sentAt.text = "Sent at: \(ChatMessageViewCell.dateFormatter?.string(from: createdAtDate) ?? "")"
        if let imageUrl = message.mediaAttachments.first?.imageUrl {
            self.imageUrl.text = "Image: \(imageUrl)"
        } else {
            self.imageUrl.text = "Image: "
        }
        if let videoUrl = message.mediaAttachments.first?.videoUrl {
            self.videoUrl.text = "Video: \(videoUrl)"
        } else {
            self.videoUrl.text = "Video: "
        }
    }

    private func addUIElements() {
        self.separatorInset = UIEdgeInsets.zero

        self.showDetailsBtn.setTitle("Details", for: .normal)
        self.showDetailsBtn.translatesAutoresizingMaskIntoConstraints = false
        self.showDetailsBtn.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        self.contentView.addSubview(self.showDetailsBtn)

        self.sender.translatesAutoresizingMaskIntoConstraints = false
        self.sender.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.sender)
        NSLayoutConstraint.activate([
            self.sender.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.sender.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            self.sender.trailingAnchor.constraint(equalTo: self.showDetailsBtn.leadingAnchor, constant: -4),
            self.sender.heightAnchor.constraint(equalToConstant: 16)
        ])

        NSLayoutConstraint.activate([
            self.showDetailsBtn.leadingAnchor.constraint(equalTo: self.sender.trailingAnchor, constant: 4),
            self.showDetailsBtn.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.showDetailsBtn.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -4),
            self.showDetailsBtn.heightAnchor.constraint(equalToConstant: 20),
            self.showDetailsBtn.widthAnchor.constraint(equalToConstant: 50)
        ])

        self.messageText.translatesAutoresizingMaskIntoConstraints = false
        self.messageText.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.messageText)
        NSLayoutConstraint.activate([
            self.messageText.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.messageText.topAnchor.constraint(equalTo: self.sender.bottomAnchor, constant: 4),
            self.messageText.trailingAnchor.constraint(equalTo: self.showDetailsBtn.leadingAnchor, constant: -4),
            self.messageText.heightAnchor.constraint(equalToConstant: 16)
        ])

        self.sentAt.translatesAutoresizingMaskIntoConstraints = false
        self.sentAt.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.sentAt)
        NSLayoutConstraint.activate([
            self.sentAt.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.sentAt.topAnchor.constraint(equalTo: self.messageText.bottomAnchor, constant: 4),
            self.sentAt.trailingAnchor.constraint(equalTo: self.showDetailsBtn.leadingAnchor, constant: -4),
            self.sentAt.heightAnchor.constraint(equalToConstant: 16)
        ])

        self.imageUrl.translatesAutoresizingMaskIntoConstraints = false
        self.imageUrl.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.imageUrl)
        NSLayoutConstraint.activate([
            self.imageUrl.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.imageUrl.topAnchor.constraint(equalTo: self.sentAt.bottomAnchor, constant: 4),
            self.imageUrl.trailingAnchor.constraint(equalTo: self.showDetailsBtn.leadingAnchor, constant: -4),
            self.imageUrl.heightAnchor.constraint(equalToConstant: 16)
        ])

        self.videoUrl.translatesAutoresizingMaskIntoConstraints = false
        self.videoUrl.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.videoUrl)
        NSLayoutConstraint.activate([
            self.videoUrl.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.videoUrl.topAnchor.constraint(equalTo: self.imageUrl.bottomAnchor, constant: 4),
            self.videoUrl.trailingAnchor.constraint(equalTo: self.showDetailsBtn.leadingAnchor, constant: -4),
            self.videoUrl.heightAnchor.constraint(equalToConstant: 16),
            self.videoUrl.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4)
        ])
    }

    @objc
    func showDetails(_ sender: Any) {
        self.onShowDetails?()
    }

}
