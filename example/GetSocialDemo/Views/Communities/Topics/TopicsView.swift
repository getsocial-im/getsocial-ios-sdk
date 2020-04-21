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
    func onFollowersClicked(ofTopic: String) {
        self.showFollowersOfTopic?(ofTopic)
    }

    func onShowFeedClicked(ofTopic: String) {
        let query = ActivitiesQuery.inTopic(id: ofTopic)
        let activitiesView = GetSocialUIActivityFeedView.init(for: query)
        GetSocialUI.show(activitiesView)
    }

    func onPostActivityClicked(topic: String) {
        let target = PostActivityTarget.topic(id: topic)
        let vc = UIStoryboard.viewController(forName: "PostActivity", in: .activityFeed) as! PostActivityViewController
        vc.postTarget = target
        self.viewController.navigationController?.pushViewController(vc, animated: true)
    }

}
