//
//  VoteOptionTableViewCell.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 03/05/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit
import GetSocialSDK

class VoteOptionTableViewCell: UITableViewCell {

	let optionId = UILabel()
	let optionText = UILabel()
	let imageURL = UILabel()
	let videoURL = UILabel()
	let voteCount = UILabel()

	public required init?(coder: NSCoder) {
		super.init(coder: coder)

		addUIElements()
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		addUIElements()
	}

	func update(_ option: PollOption, selected: Bool) {
		self.optionId.text = "Id: \(option.optionId)"
		self.optionText.text = "Text: \(option.text ?? "")"
		self.imageURL.text = "Image URL: \(option.attachment?.imageUrl ?? "")"
		self.videoURL.text = "Video URL: \(option.attachment?.videoUrl ?? "")"
		self.voteCount.text = "Vote count: \(option.voteCount)"
		self.accessoryType = selected ? .checkmark : .none
	}

	private func addUIElements() {
		let stackView = UIStackView()
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		stackView.spacing = 4
		self.contentView.addSubview(stackView)

		stackView.addArrangedSubview(self.optionId)
		stackView.addArrangedSubview(self.optionText)
		stackView.addArrangedSubview(self.imageURL)
		stackView.addArrangedSubview(self.videoURL)
		stackView.addArrangedSubview(self.voteCount)

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
			stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
		])
	}
}
