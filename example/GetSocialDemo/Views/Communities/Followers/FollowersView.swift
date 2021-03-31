//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class FollowersView {

    var viewController: FollowersViewController

    var showFollowersOfUser: ((UserId, Int) -> Void)?
    var followersCount: Int = 0 {
        didSet {
            self.viewController.followersCount = self.followersCount
        }
    }

    var query: FollowersQuery? {
        didSet {
            self.viewController.query = self.query
        }
    }

    init() {
        self.viewController = FollowersViewController()
        self.viewController.delegate = self
    }
}

extension FollowersView: FollowersViewControllerDelegate {

    func onFollowersClicked(ofUser: UserId, followersCount: Int) {
        self.showFollowersOfUser?(ofUser, followersCount)
    }
}
