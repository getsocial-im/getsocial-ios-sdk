//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import GetSocialSDK

protocol PollsModel {
	var onInitialDataLoaded: (() -> Void)? { get set }
	var onError: ((Error) -> Void)?  { get set }
	var reactionUpdated: ((Int) -> Void)?  { get set }

	var activities: [Activity] { get set }

	func loadEntries(pollStatus: PollStatus)
	func numberOfEntries() -> Int
	func entry(at: Int) -> Activity
	func findActivity(_ activityId: String) -> Activity?
	func updateModel(_ activity: Activity) -> Int
}

extension PollsModel {
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
}

class ActivityPollsModel: PollsModel {

    var onInitialDataLoaded: (() -> Void)?
    var onError: ((Error) -> Void)?
    var reactionUpdated: ((Int) -> Void)?

	var query: ActivitiesQuery

    var activities: [Activity] = []

	init(_ query: ActivitiesQuery) {
		self.query = query
	}

	func loadEntries(pollStatus: PollStatus) {
		self.activities.removeAll()
		self.query = self.query.withPollStatus(pollStatus)
		executeQuery(success: {
			self.onInitialDataLoaded?()
		}, failure: onError)
	}

	func updateModel(_ activity: Activity) -> Int {
		let index = findActivityIndex(activity.id)
		self.activities[index] = activity
		return index
	}


	func refreshActivity(_ activityId: String) {
		Communities.activity(activityId, success: { activity in
			let replacedModelIndex = self.updateModel(activity)
			if replacedModelIndex != -1 {
				self.reactionUpdated?(replacedModelIndex)
			}
		}, failure: { error in
			self.onError?(error)
		})
	}

    func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
		let pagingQuery = ActivitiesPagingQuery(self.query)
        Communities.activities(pagingQuery, success: { result in
            self.activities.append(contentsOf: result.activities)
            success?()
        }) { error in
            failure?(error)
        }
    }
}

class AnnouncementPollsModel: PollsModel {

	var onInitialDataLoaded: (() -> Void)?
	var onError: ((Error) -> Void)?
	var reactionUpdated: ((Int) -> Void)?

	var query: AnnouncementsQuery

	var activities: [Activity] = []

	init(_ query: AnnouncementsQuery) {
		self.query = query
	}

	func loadEntries(pollStatus: PollStatus) {
		self.activities.removeAll()
		self.query = self.query.withPollStatus(pollStatus)
		executeQuery(success: {
			self.onInitialDataLoaded?()
		}, failure: onError)
	}

	func updateModel(_ activity: Activity) -> Int {
		let index = findActivityIndex(activity.id)
		self.activities[index] = activity
		return index
	}


	func refreshActivity(_ activityId: String) {
		Communities.activity(activityId, success: { activity in
			let replacedModelIndex = self.updateModel(activity)
			if replacedModelIndex != -1 {
				self.reactionUpdated?(replacedModelIndex)
			}
		}, failure: { error in
			self.onError?(error)
		})
	}

	func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
		Communities.announcements(self.query, success: { result in
			self.activities.append(contentsOf: result)
			success?()
		}) { error in
			failure?(error)
		}
	}



}
