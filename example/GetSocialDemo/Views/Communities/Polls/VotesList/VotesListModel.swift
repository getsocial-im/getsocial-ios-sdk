//
//  VotesListModel.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 07/05/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation

class VotesListModel {

	private let activityId: String

	var onVotesLoaded: (() -> Void)?
	var onError: ((String) -> Void)?
	var votes: [UserVotes] = []

	init(_ activityId: String) {
		self.activityId = activityId
	}

	func loadVotes() {
		let query = VotesQuery.forActivity(self.activityId)
		Communities.votes(VotesPagingQuery(query), success: { [weak self] result in
			self?.votes = result.votes
			self?.onVotesLoaded?()
		}, failure: { [weak self] error in
			self?.onError?(error.localizedDescription)
		})
	}
}
