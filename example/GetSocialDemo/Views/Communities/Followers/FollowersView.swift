//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class FollowersView {

    var viewController: FollowersViewController
    var query: FollowersQuery? {
        didSet {
            self.viewController.query = self.query
        }
    }

    init() {
        self.viewController = FollowersViewController()
    }
}
