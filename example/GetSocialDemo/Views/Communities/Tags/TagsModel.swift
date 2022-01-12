//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class TagsModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?
    var tagFollowed: ((Int) -> Void)?
    var tagUnfollowed: ((Int) -> Void)?

    var pagingQuery: TagsPagingQuery?
    var query: TagsQuery?

    var tags: [Tag] = []
    var nextCursor: String = ""

    func loadEntries(query: TagsQuery) {
        self.query = query
        self.pagingQuery = TagsPagingQuery.init(query)
        self.tags.removeAll()
        executeQuery(success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
    }
    
    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.tags.removeAll()
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
        return self.tags.count
    }

    func entry(at: Int) -> Tag {
        return self.tags[at]
    }
    
    func findTag(_ name: String) -> Tag? {
        return self.tags.filter {
            return $0.name == name
        }.first
    }

	func followTag(_ name: String, remove: Bool = false) {
        if let tag = findTag(name), let tagIndex = self.tags.firstIndex(of: tag) {
            let query = FollowQuery.tags([name])
            if tag.isFollowedByMe {
                Communities.unfollow(query, success: { _ in
					if remove {
						self.tags.remove(at: tagIndex)
					} else {
						PrivateTagBuilder.updateTag(tag: tag, isFollowed: false)
					}
                    self.tagUnfollowed?(tagIndex)
                }) { error in
                    self.onError?(error)
                }

            } else {
                Communities.follow(query, success: { _ in
                    PrivateTagBuilder.updateTag(tag: tag, isFollowed: true)
                    self.tagFollowed?(tagIndex)
                }) { error in
                    self.onError?(error)
                }
            }
        }

    }
    
    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        Communities.tags(self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.tags.append(contentsOf: result.tags)
            success?()
        }) { error in
            failure?(error)
        }
    }
}
