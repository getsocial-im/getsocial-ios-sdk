//
//  CreatePollViewModel.swift
//  GetSocialDemo
//
//  Created by Gábor Vass on 26/04/2021.
//  Copyright © 2021 GrambleWorld. All rights reserved.
//

import Foundation

class CreatePollViewModel {

	var onError: ((String) -> Void)?
	var onSuccess: (() -> Void)?

	let target: PostActivityTarget

	init(_ target: PostActivityTarget) {
		self.target = target
	}

	func createPoll(_ content: ActivityContent) {
		Communities.postActivity(content, target: self.target, success: { [weak self] result in
			self?.onSuccess?()
		}, failure: { [weak self] error in
			self?.onError?(error.localizedDescription)
		})

	}
}
