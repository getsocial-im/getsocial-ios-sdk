//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialUI

class TopicsView {

    var viewController: TopicsViewController
    var showFollowersOfTopic: ((String) -> Void)?

    init() {
        self.viewController = TopicsViewController()
        self.viewController.delegate = self
    }
}

extension TopicsView: TopicTableViewControllerDelegate {
    func onShowFollowers(_ ofTopic: String) {
        self.showFollowersOfTopic?(ofTopic)
    }

    func onShowFeed(_ ofTopic: String) {
        let query = ActivitiesQuery.inTopic(ofTopic)
        let activitiesView = GetSocialUIActivityFeedView.init(for: query)
        activitiesView.setActionHandler { action in
            let mainVC = self.viewController.parent?.parent as? MainViewController
            mainVC?.handle(action)
        }
        activitiesView.setCustomErrorMessageProvider { (code, message) -> String? in
            if code == ErrorCode.ActivityRejected {
                return "Be careful what you say :)"
            }
            return message
        }
        GetSocialUI.show(activitiesView)
    }

	func onShowFeed(_ ofTopic: String, byCurrentUser: Bool) {
		var query = ActivitiesQuery.inTopic(ofTopic)
		if byCurrentUser {
			query = query.byUser(UserId.currentUser())
		}
		let activitiesView = GetSocialUIActivityFeedView.init(for: query)
		activitiesView.setActionHandler { action in
			let mainVC = self.viewController.parent?.parent as? MainViewController
			mainVC?.handle(action)
		}
		activitiesView.setCustomErrorMessageProvider { (code, message) -> String? in
			if code == ErrorCode.ActivityRejected {
				return "Be careful what you say :)"
			}
			return message
		}
		GetSocialUI.show(activitiesView)
	}

    func onPostActivity(_ topic: String) {
        let target = PostActivityTarget.topic(topic)
        let vc = UIStoryboard.viewController(forName: "PostActivity", in: .activityFeed) as! PostActivityViewController
        vc.postTarget = target
        self.viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
