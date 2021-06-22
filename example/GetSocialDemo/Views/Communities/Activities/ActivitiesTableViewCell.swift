//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

class ActivitiesTableViewCell: UITableViewCell {

    var internalActivityId: String?

    var activityAuthor: UILabel = UILabel()
    var activityText: UILabel = UILabel()

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
    }
}
