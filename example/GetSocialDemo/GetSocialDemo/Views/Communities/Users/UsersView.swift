//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit

class UsersView {

    var viewController: UsersViewController
    var showFollowersOfUser: ((UserId, Int) -> Void)?
    var showFollowingsOfUser: ((UserId) -> Void)?

    var query: UsersQuery? {
        didSet {
            self.viewController.query = self.query
        }
    }

    init() {
        self.viewController = UsersViewController()
        self.viewController.delegate = self
    }
}

extension UsersView: UsersViewControllerDelegate {

    func onFollowersClicked(ofUser: UserId, followersCount: Int) {
        self.showFollowersOfUser?(ofUser, followersCount)
    }

    func onFollowingsClicked(ofUser: UserId) {
        self.showFollowingsOfUser?(ofUser)
    }
}
