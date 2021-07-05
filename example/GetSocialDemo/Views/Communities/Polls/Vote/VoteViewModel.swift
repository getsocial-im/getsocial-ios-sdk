//
//  VoteModel.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 03/05/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation
import GetSocialSDK

class VoteViewModel {
	let activityId: String

	var poll: Poll?
	var pollOptions: [PollOption] = []
	var myVotes = [String]()
	var selectedPollOptions: [String] = []

	var onPollOptionsAvailable: (() -> Void)?
	var onVotesAdded: (() -> Void)?
	var onVotesSet: (() -> Void)?
	var onVotesRemoved: (() -> Void)?
	var onVotesAddedError: ((String) -> Void)?
	var onVotesSetError: ((String) -> Void)?
	var onVotesRemovedError: ((String) -> Void)?
	var onError: ((String) -> Void)?

	init(_ activityId: String) {
		self.activityId = activityId
	}

	func loadPoll() {
		self.pollOptions = []
		self.selectedPollOptions = []
		self.myVotes = []
		Communities.activity(self.activityId, success: { activity in
			guard let poll = activity.poll, poll.options.count > 0 else {
				self.onError?("no poll options available")
				return
			}
			self.poll = poll
			self.pollOptions = poll.options
			self.pollOptions.forEach {
				if $0.isVotedByMe {
					self.selectedPollOptions.append($0.optionId)
					self.myVotes.append($0.optionId)
				}
			}
			self.onPollOptionsAvailable?()
		}, failure: { error in
			self.onError?(error.localizedDescription)
		})
	}

	func isRemoveButtonEnabled() -> Bool {
		var result = false
		self.myVotes.forEach {
			if self.selectedPollOptions.contains($0) {
				result = true
			}
		}
		return result
	}

	func markOption(_ optionId: String) {
		if self.selectedPollOptions.contains(optionId) {
			self.selectedPollOptions = self.selectedPollOptions.filter {
				return optionId != $0
			}
		} else {
			if self.selectedPollOptions.count > 0 && !(self.poll?.allowMultipleVotes ?? false) {
				self.selectedPollOptions.removeAll()
			}
			self.selectedPollOptions.append(optionId)
		}
		self.onPollOptionsAvailable?()
	}

	func addVotes() {
		Communities.addVotes(Set(self.selectedPollOptions), activityId: self.activityId, success: { [weak self] in
			self?.loadPoll()
			self?.onVotesAdded?()
		}, failure: { [weak self] error in
			self?.onVotesAddedError?(error.localizedDescription)
		})
	}

	func setVotes() {
		Communities.setVotes(Set(self.selectedPollOptions), activityId: self.activityId, success: { [weak self] in
			self?.loadPoll()
			self?.onVotesSet?()
		}, failure: { [weak self] error in
			self?.onVotesSetError?(error.localizedDescription)
		})
	}

	func removeVotes() {
		Communities.removeVotes(Set(self.selectedPollOptions), activityId: self.activityId, success: { [weak self] in
			self?.loadPoll()
			self?.onVotesRemoved?()
		}, failure: { [weak self] error in
			self?.onVotesSetError?(error.localizedDescription)
		})
	}
}
