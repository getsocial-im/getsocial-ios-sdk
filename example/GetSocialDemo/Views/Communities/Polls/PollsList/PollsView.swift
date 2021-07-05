//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialSDK

class PollsView {

    var viewController: PollsViewController
	var showVote: ((Activity) -> Void)?
	var showAllVotes: ((Activity) -> Void)?


	init(_ query: ActivitiesQuery) {
        self.viewController = PollsViewController(query)
        self.viewController.delegate = self
    }

	init(_ query: AnnouncementsQuery) {
		self.viewController = PollsViewController(query)
		self.viewController.delegate = self
	}
}

extension PollsView: PollsTableViewControllerDelegate {
	func onShowAllVotes(_ activity: Activity) {
		self.showAllVotes?(activity)
	}
	func onVote(_ activity: Activity) {
		self.showVote?(activity)
	}
}
