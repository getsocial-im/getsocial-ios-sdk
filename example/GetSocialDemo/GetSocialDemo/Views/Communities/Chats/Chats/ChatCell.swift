//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol ChatCellDelegate {
    func onShowChat(_ chat: Chat)
}

class ChatCell: UITableViewCell {

    static var dateFormatter: DateFormatter?

    var delegate: ChatCellDelegate?
    var onShowDetails: (() -> Void)?

    var avatar: UIImageView = UIImageView()
    var title: UILabel = UILabel()
    var lastMessageText: UILabel = UILabel()
    var lastMessageImage: UILabel = UILabel()
    var lastMessageVideo: UILabel = UILabel()
    var actionButton: UIButton = UIButton.init(type: .roundedRect)
    var detailsButton: UIButton = UIButton.init(type: .roundedRect)
    var chat: Chat?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addUIElements()
    }

    func update(_ chat: Chat) {
        self.chat = chat
        if let avatarUrl = chat.avatarUrl {
            loadAvatarImage(avatarUrl)
        } else {
            self.avatar.image = UIImage.init(named: "defaultAvatar.png")
        }
        self.title.text = "\(chat.title)"
        if chat.title.count == 0 {
            self.title.text = "NA"
        }
        if let lastMessage = chat.lastMessage {
            self.lastMessageText.text = "Text: \(lastMessage.text ?? "")"
            if let imageUrl = lastMessage.mediaAttachments.first?.imageUrl {
                self.lastMessageImage.text = "Image: \(imageUrl)"
            } else {
                self.lastMessageImage.text = "Image: "
            }
            if let videoUrl = lastMessage.mediaAttachments.first?.videoUrl {
                self.lastMessageVideo.text = "Video: \(videoUrl)"
            } else {
                self.lastMessageVideo.text = "Video: "
            }
        }
    }

    private func loadAvatarImage(_ url: String) {
        DispatchQueue.global().async {
            if let imageData = try? Data.init(contentsOf: URL(string: url)!) {
                if let image = UIImage.init(data: imageData) {
                    DispatchQueue.main.async {
                        self.avatar.image = image
                    }
                }
            }
        }
    }

    private func addUIElements() {
        self.separatorInset = UIEdgeInsets.zero
        self.avatar.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.avatar)

        self.title.translatesAutoresizingMaskIntoConstraints = false
        self.title.font = UIFont.boldSystemFont(ofSize: 16.0)
        self.title.numberOfLines = 1
        self.title.lineBreakMode = .byTruncatingTail
        self.contentView.addSubview(self.title)

        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.actionButton.setTitle("Open", for: .normal)
        self.actionButton.addTarget(self, action: #selector(showChat), for: .touchUpInside)
        self.contentView.addSubview(self.actionButton)

        self.detailsButton.translatesAutoresizingMaskIntoConstraints = false
        self.detailsButton.setTitle("Details", for: .normal)
        self.detailsButton.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        self.contentView.addSubview(self.detailsButton)

        NSLayoutConstraint.activate([
            self.avatar.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.avatar.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.avatar.widthAnchor.constraint(equalToConstant: 40),
            self.avatar.heightAnchor.constraint(equalToConstant: 40),
            self.avatar.trailingAnchor.constraint(equalTo: self.title.leadingAnchor, constant: -4)
        ])

        NSLayoutConstraint.activate([
            self.title.leadingAnchor.constraint(equalTo: self.avatar.trailingAnchor, constant: 4),
            self.title.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            self.title.trailingAnchor.constraint(equalTo: self.actionButton.leadingAnchor, constant: -4),
            self.title.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.lastMessageText.translatesAutoresizingMaskIntoConstraints = false
        self.lastMessageText.font = UIFont.italicSystemFont(ofSize: 12)
        self.contentView.addSubview(self.lastMessageText)
        NSLayoutConstraint.activate([
            self.lastMessageText.leadingAnchor.constraint(equalTo: self.title.leadingAnchor),
            self.lastMessageText.topAnchor.constraint(equalTo: self.title.bottomAnchor, constant: 2),
            self.lastMessageText.trailingAnchor.constraint(equalTo: self.title.trailingAnchor),
            self.lastMessageText.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.lastMessageImage.translatesAutoresizingMaskIntoConstraints = false
        self.lastMessageImage.font = UIFont.italicSystemFont(ofSize: 12)
        self.contentView.addSubview(self.lastMessageImage)
        NSLayoutConstraint.activate([
            self.lastMessageImage.leadingAnchor.constraint(equalTo: self.title.leadingAnchor),
            self.lastMessageImage.topAnchor.constraint(equalTo: self.lastMessageText.bottomAnchor, constant: 2),
            self.lastMessageImage.trailingAnchor.constraint(equalTo: self.title.trailingAnchor),
            self.lastMessageImage.heightAnchor.constraint(equalToConstant: 20)
        ])

        self.lastMessageVideo.translatesAutoresizingMaskIntoConstraints = false
        self.lastMessageVideo.font = UIFont.italicSystemFont(ofSize: 12)
        self.contentView.addSubview(self.lastMessageVideo)
        NSLayoutConstraint.activate([
            self.lastMessageVideo.leadingAnchor.constraint(equalTo: self.title.leadingAnchor),
            self.lastMessageVideo.topAnchor.constraint(equalTo: self.lastMessageImage.bottomAnchor, constant: 2),
            self.lastMessageVideo.trailingAnchor.constraint(equalTo: self.title.trailingAnchor),
            self.lastMessageVideo.heightAnchor.constraint(equalToConstant: 20)
        ])


        NSLayoutConstraint.activate([
            self.actionButton.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            self.actionButton.leadingAnchor.constraint(equalTo: self.title.trailingAnchor, constant: 4),
            self.actionButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),
            self.actionButton.widthAnchor.constraint(equalToConstant: 50),
            self.actionButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        NSLayoutConstraint.activate([
            self.detailsButton.topAnchor.constraint(equalTo: self.actionButton.bottomAnchor, constant: 4),
            self.detailsButton.leadingAnchor.constraint(equalTo: self.title.trailingAnchor, constant: 4),
            self.detailsButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),
            self.detailsButton.widthAnchor.constraint(equalToConstant: 50),
            self.detailsButton.heightAnchor.constraint(equalToConstant: 30)
        ])

    }

    @objc
    private func showChat() {
        self.delegate?.onShowChat(self.chat!)
    }

    @objc
    private func showDetails() {
        self.onShowDetails?()
    }

}
