//
//  GenericTableViewCell.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

protocol PollTableViewCellDelegate {
    func onShowActions(_ ofActivity: String)
}

class PollTableViewCell: UITableViewCell {

    var internalActivityId: String?

    var pollText: UILabel = UILabel()
    var totalVotes: UILabel = UILabel()

	var actionButton: UIButton = UIButton.init(type: .roundedRect)

    var delegate: PollTableViewCellDelegate?

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
		self.pollText.text = "Text: \(activity.text ?? "")"
		self.totalVotes.text = "Total votes: \(activity.poll?.totalVotes ?? 0)"
        self.actionButton.setTitle("Actions", for: .normal)
        self.actionButton.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)


    }

    @objc
    func showActions(sender: Any?) {
        self.delegate?.onShowActions(self.internalActivityId!)
    }

    private func addUIElements() {
		self.actionButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
		self.actionButton.setTitleColor(.black, for: .normal)
		self.actionButton.backgroundColor = .lightGray
		self.actionButton.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(self.actionButton)

		let stackView = UIStackView()
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		stackView.spacing = 4

		stackView.addArrangedSubview(self.pollText)
		stackView.addArrangedSubview(self.totalVotes)

		self.contentView.addSubview(stackView)

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: self.actionButton.leadingAnchor, constant: -8),
			stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
			self.actionButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),
			self.actionButton.widthAnchor.constraint(equalToConstant: 80),
			self.actionButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
		])
    }
}
