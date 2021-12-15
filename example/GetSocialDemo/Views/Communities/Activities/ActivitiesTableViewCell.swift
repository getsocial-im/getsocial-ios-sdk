//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

class ActivitiesTableViewCell: UITableViewCell {

	static var dateFormatter: DateFormatter?

	var internalActivityId: String?

	var activityAuthor: UILabel = UILabel()
	var activityText: UILabel = UILabel()
	var createdAtText: UILabel = UILabel()
	var scoreText: UILabel = UILabel()
	var labels: UILabel = UILabel()
	var properties: UILabel = UILabel()

	public required init?(coder: NSCoder) {
		super.init(coder: coder)

		if ActivitiesTableViewCell.dateFormatter == nil {
			ActivitiesTableViewCell.dateFormatter = DateFormatter()
			ActivitiesTableViewCell.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
		}

		addUIElements()
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		if ActivitiesTableViewCell.dateFormatter == nil {
			ActivitiesTableViewCell.dateFormatter = DateFormatter()
			ActivitiesTableViewCell.dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss"
		}

		addUIElements()
	}


	func update(activity: Activity) {
		self.internalActivityId = activity.id
		self.activityAuthor.text = "Author: \(activity.author.displayName)"
		self.activityText.text = "Text: \(activity.text ?? "")"

		let createdAtDate = Date.init(timeIntervalSince1970: TimeInterval(activity.createdAt))
		self.createdAtText.text = "Created: \(ActivitiesTableViewCell.dateFormatter?.string(from: createdAtDate) ?? "")"

		self.scoreText.text = "Popularity: \(activity.popularity)"
		self.labels.text = "Labels: \(activity.labels.joined(separator: ","))"
		self.properties.text = "Properties: \(activity.properties.map { "\($0)=\($1)" }.joined(separator: ","))"
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

		self.createdAtText.translatesAutoresizingMaskIntoConstraints = false
		self.createdAtText.font = self.createdAtText.font.withSize(12)
		self.contentView.addSubview(self.createdAtText)
		let activityCreatedAtConstraints = [
			self.createdAtText.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.createdAtText.topAnchor.constraint(equalTo: self.activityText.bottomAnchor, constant: 4)
		]
		NSLayoutConstraint.activate(activityCreatedAtConstraints)

		self.scoreText.translatesAutoresizingMaskIntoConstraints = false
		self.scoreText.font = self.scoreText.font.withSize(12)
		self.contentView.addSubview(self.scoreText)
		let activityScoreConstraints = [
			self.scoreText.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.scoreText.topAnchor.constraint(equalTo: self.createdAtText.bottomAnchor, constant: 4)
		]
		NSLayoutConstraint.activate(activityScoreConstraints)

		self.labels.translatesAutoresizingMaskIntoConstraints = false
		self.labels.font = self.labels.font.withSize(12)
		self.contentView.addSubview(self.labels)

		let labelsConstraints = [
			self.labels.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.labels.topAnchor.constraint(equalTo: self.scoreText.bottomAnchor, constant: 4)
		]
		NSLayoutConstraint.activate(labelsConstraints)

		self.properties.translatesAutoresizingMaskIntoConstraints = false
		self.properties.font = self.properties.font.withSize(12)
		self.contentView.addSubview(self.properties)

		let propertiesConstraints = [
			self.properties.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
			self.properties.topAnchor.constraint(equalTo: self.labels.bottomAnchor, constant: 4)
		]
		NSLayoutConstraint.activate(propertiesConstraints)

	}
}
