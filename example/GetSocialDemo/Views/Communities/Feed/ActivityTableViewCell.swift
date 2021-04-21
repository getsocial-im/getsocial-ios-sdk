//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol ActivityTableViewCellDelegate {
    func onShowActions(_ ofActivity: String)
}

class ActivityTableViewCell: UITableViewCell {

    var internalActivityId: String?

    var activityAuthor: UILabel = UILabel()
    var activityText: UILabel = UILabel()
    var reactions: UILabel = UILabel()

	var actionButton: UIButton = UIButton.init(type: .roundedRect)

    var delegate: ActivityTableViewCellDelegate?

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        addUIElements()
    }

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		addUIElements()
	}


    func update(activity: Activity) {
		self.internalActivityId = activity.id
		self.activityAuthor.text = "Author: \(activity.author.displayName)"
		self.activityText.text = "Text: \(activity.text ?? "")"
		self.reactions.text = "My reactions: \(activity.myReactions.joined(separator: ", "))"

        self.actionButton.setTitle("Actions", for: .normal)
        self.actionButton.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)


    }

    @objc
    func showActions(sender: Any?) {
        self.delegate?.onShowActions(self.internalActivityId!)
    }

    private func addUIElements() {
		self.activityAuthor.translatesAutoresizingMaskIntoConstraints = false
        self.activityAuthor.font = self.activityAuthor.font.withSize(14)
        self.contentView.addSubview(self.activityAuthor)
        let activityAuthorConstraints = [
            self.activityAuthor.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.activityAuthor.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(activityAuthorConstraints)

        self.activityText.translatesAutoresizingMaskIntoConstraints = false
        self.activityText.font = self.activityText.font.withSize(12)
        self.contentView.addSubview(self.activityText)
        let activityTextConstraints = [
            self.activityText.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.activityText.topAnchor.constraint(equalTo: self.activityAuthor.bottomAnchor, constant: 4)
        ]
        NSLayoutConstraint.activate(activityTextConstraints)

		self.reactions.translatesAutoresizingMaskIntoConstraints = false
		self.reactions.font = self.reactions.font.withSize(12)
		self.contentView.addSubview(self.reactions)
		let reactionsConstraints = [
			self.reactions.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.reactions.topAnchor.constraint(equalTo: self.activityText.bottomAnchor, constant: 4)
		]
		NSLayoutConstraint.activate(reactionsConstraints)

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
