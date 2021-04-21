//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialUI

class FeedView {

    var viewController: FeedViewController

    init() {
        self.viewController = FeedViewController()
        self.viewController.delegate = self
    }
}

extension FeedView: FeedTableViewControllerDelegate {

}
