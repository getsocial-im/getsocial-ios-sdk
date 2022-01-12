//
//  LabelsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class LabelsView {

	var showFollowersOfLabel: ((String) -> Void)?

    var viewController: LabelsViewController

    init(followedByCurrentUser: Bool = false) {
        self.viewController = LabelsViewController()
		self.viewController.delegate = self
		self.viewController.followedByCurrentUser = followedByCurrentUser
    }
}

extension LabelsView: LabelsViewControllerDelegate {
	func onShowFollowers(_ ofLabel: String) {
		self.showFollowersOfLabel?(ofLabel)
	}
}
