//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import GetSocialSDK

class FeedModel {

    var onInitialDataLoaded: (() -> Void)?
    var onError: ((Error) -> Void)?
    var reactionUpdated: ((Int) -> Void)?

	let query = ActivitiesQuery.timeline()

    var activities: [Activity] = []

    func loadEntries() {
        self.activities.removeAll()
        executeQuery(success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
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

	func addReaction(_ reaction: String, activityId: String) {
		Communities.addReaction(reaction, activityId: activityId, success: {
			self.refreshActivity(activityId)
		}, failure: { error in
			self.onError?(error)
		})
	}

	func setReaction(_ reaction: String, activityId: String) {
		Communities.setReaction(reaction, activityId: activityId, success: {
			self.refreshActivity(activityId)
		}, failure: { error in
			self.onError?(error)
		})
	}

	func removeReaction(_ reaction: String, activityId: String) {
		Communities.removeReaction(reaction, activityId: activityId, success: {
			self.refreshActivity(activityId)
		}, failure: { error in
			self.onError?(error)
		})
	}

	private func refreshActivity(_ activityId: String) {
		Communities.activity(activityId, success: { activity in
			let replacedModelIndex = self.updateModel(activity)
			if replacedModelIndex != -1 {
				self.reactionUpdated?(replacedModelIndex)
			}
		}, failure: { error in
			self.onError?(error)
		})
	}

    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
		let pagingQuery = ActivitiesPagingQuery(ActivitiesQuery.inTopic("DemoFeed"))
        Communities.activities(pagingQuery, success: { result in
            self.activities.append(contentsOf: result.activities)
            success?()
        }) { error in
            failure?(error)
        }
    }

}
