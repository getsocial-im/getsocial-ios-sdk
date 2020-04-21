//
//  CommunitiesObjCHelper.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

@objcMembers
public class CommunitiesHelper: NSObject {
    
    public static func showTopics(navigationController: UINavigationController) {
        let topicsView = TopicsView()
        navigationController.pushViewController(topicsView.viewController, animated: true)

        topicsView.showFollowersOfTopic = { topicId in
            let followersView = FollowersView()
            followersView.query = FollowersQuery.ofTopic(id: topicId)
            navigationController.pushViewController(followersView.viewController, animated: true)
        }
    }

    public static func showFollowers(navigationController: UINavigationController) {
        let followersView = FollowersView()
        navigationController.pushViewController(followersView.viewController, animated: true)
    }

    public static func showUsers(navigationController: UINavigationController) {
        let usersView = UsersView()
        navigationController.pushViewController(usersView.viewController, animated: true)
    }

}
