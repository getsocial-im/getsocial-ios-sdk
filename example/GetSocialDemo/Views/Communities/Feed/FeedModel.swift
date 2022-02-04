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
    var onDidOlderLoad: (() -> Void)?
    var onError: ((Error) -> Void)?
    var reactionUpdated: ((Int) -> Void)?
    
    var pagingQuery: ActivitiesPagingQuery?
    var query: ActivitiesQuery?

    var activities: [Activity] = []
    var nextCursor: String = ""
    
    func loadEntries(query: ActivitiesQuery) {
        self.query = query
        self.pagingQuery = ActivitiesPagingQuery.init(query)
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }
    
    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.activities.removeAll()
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }
    
    func loadOlder() {
        self.pagingQuery?.nextCursor = self.nextCursor
        executeQuery(success: onDidOlderLoad, failure: onError)
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
    
    func bookmark(_ activityId: String) {
        Communities.bookmark(activityId, success: {
            self.refreshActivity(activityId)
        }, failure: { error in
            self.onError?(error)
        })
    }
    
    func removeBookmark(_ activityId: String) {
        Communities.removeBookmark(activityId, success: {
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
        Communities.activities(self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.activities.append(contentsOf: result.activities)
            success?()
        }) { error in
            failure?(error)
        }
    }

}
