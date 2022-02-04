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

    public init() {
        self.viewController = FeedViewController()
        self.viewController.delegate = self
    }
    
    var query: ActivitiesQuery? {
        didSet {
            self.viewController.query = self.query
        }
    }

}

extension FeedView: FeedTableViewControllerDelegate {

}
