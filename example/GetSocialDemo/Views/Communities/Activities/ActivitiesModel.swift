//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import GetSocialSDK

class ActivitiesModel {

    var onInitialDataLoaded: (() -> Void)?
    var onError: ((Error) -> Void)?

	init() {
	}

    var activities: [Activity] = []

	func loadEntries(_ query: ActivitiesQuery) {
        self.activities.removeAll()
        executeQuery(query, success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
    }
    
    func loadEntries(_ activities: [Activity]) {
        self.activities.removeAll()
        
        self.activities.append(contentsOf: activities)
        self.onInitialDataLoaded?()
    }


    func numberOfEntries() -> Int {
        return self.activities.count
    }

    func entry(at: Int) -> Activity {
        return self.activities[at]
    }

    func findActivity(_ activityId: String) -> Activity? {
        return self.activities.filter {
            return $0.id == activityId
        }.first
    }

	func findActivityIndex(_ activityId: String) -> Int {
		if let activity = findActivity(activityId) {
			return self.activities.firstIndex(of: activity) ?? -1
		}
		return -1
	}

	func updateModel(_ activity: Activity) -> Int {
		let index = findActivityIndex(activity.id)
		self.activities[index] = activity
		return index
	}

	private func executeQuery(_ query: ActivitiesQuery, success: (() -> Void)?, failure: ((Error) -> Void)?) {
		let pagingQuery = ActivitiesPagingQuery(query)
        Communities.activities(pagingQuery, success: { result in
            self.activities.append(contentsOf: result.activities)
            success?()
        }) { error in
            failure?(error)
        }
    }

}
