//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialUI

class ActivitiesView {

	let viewController: ActivitiesViewController

	init(_ query: ActivitiesQuery) {
        self.viewController = ActivitiesViewController(query)
    }
    
    init(_ activities: [Activity]) {
        self.viewController = ActivitiesViewController(activities)
    }
}
