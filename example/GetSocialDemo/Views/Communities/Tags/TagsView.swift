//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class TagsView {

	var showFollowersOfTag: ((String) -> Void)?

    var viewController: TagsViewController

	init(followedByCurrentUser: Bool = false) {
        self.viewController = TagsViewController()
		self.viewController.delegate = self
		self.viewController.followedByCurrentUser = followedByCurrentUser
    }
}

extension TagsView: TagsViewControllerDelegate {
	func onShowFollowers(_ ofTag: String) {
		self.showFollowersOfTag?(ofTag)
	}
}
