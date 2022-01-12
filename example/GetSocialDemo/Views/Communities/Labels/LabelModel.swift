//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class LabelsModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?
    var labelFollowed: ((Int) -> Void)?
    var labelUnfollowed: ((Int) -> Void)?

    var pagingQuery: LabelsPagingQuery?
    var query: LabelsQuery?

    var labels: [Label] = []
    var nextCursor: String = ""

    func loadEntries(query: LabelsQuery) {
        self.query = query
        self.pagingQuery = LabelsPagingQuery.init(query)
        self.labels.removeAll()
        executeQuery(success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
    }
    
    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.labels.removeAll()
        executeQuery(success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
    }

    func loadOlder() {
        if self.nextCursor.count == 0 {
            onDidOlderLoad?(false)
            return
        }
        self.pagingQuery?.nextCursor = self.nextCursor
        executeQuery(success: {
            self.onDidOlderLoad?(true)
        }, failure: onError)
    }

    func numberOfEntries() -> Int {
        return self.labels.count
    }

    func entry(at: Int) -> Label {
        return self.labels[at]
    }
    
    func findLabel(_ name: String) -> Label? {
        return self.labels.filter {
            return $0.name == name
        }.first
    }

	func followLabel(_ name: String, remove: Bool = false) {
        if let label = findLabel(name), let labelIndex = self.labels.firstIndex(of: label) {
            let query = FollowQuery.labels([name])
            if label.isFollowedByMe {
                Communities.unfollow(query, success: { _ in
					if remove {
						self.labels.remove(at: labelIndex)
					} else {
						PrivateLabelBuilder.updateLabel(label: label, isFollowed: false)
					}
                    self.labelUnfollowed?(labelIndex)
                }) { error in
                    self.onError?(error)
                }

            } else {
                Communities.follow(query, success: { _ in
                    PrivateLabelBuilder.updateLabel(label: label, isFollowed: true)
                    self.labelFollowed?(labelIndex)
                }) { error in
                    self.onError?(error)
                }
            }
        }

    }
    
    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        Communities.labels(self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.labels.append(contentsOf: result.labels)
            success?()
        }) { error in
            failure?(error)
        }
    }
}
