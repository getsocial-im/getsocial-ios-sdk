//
//  VoteView.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 07/05/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import UIKit
import GetSocialSDK

class VoteView: UIView {
	
	let userName = UILabel()
	let votes = UILabel()

	required override init(frame: CGRect) {
		super.init(frame: frame)
		layout()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		layout()
	}

	func update(_ vote: UserVotes) {
		self.userName.text = "User: \(vote.user.displayName)"
		self.votes.text = "Votes: \(vote.votes)"
	}

	func layout() {
		self.translatesAutoresizingMaskIntoConstraints = false
		let stack = UIStackView()
		stack.translatesAutoresizingMaskIntoConstraints = false
		stack.axis = .vertical
		stack.spacing = 4

		stack.addArrangedSubview(userName)
		stack.addArrangedSubview(votes)

		self.addSubview(stack)

		NSLayoutConstraint.activate([
			stack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			stack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			stack.topAnchor.constraint(equalTo: self.topAnchor),
			stack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
		])
	}
}
