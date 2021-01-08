//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class TopicsModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?
    var topicFollowed: ((Int) -> Void)?
    var topicUnfollowed: ((Int) -> Void)?

    var pagingQuery: TopicsPagingQuery?
    var query: TopicsQuery?

    var topics: [Topic] = []
    var nextCursor: String = ""

    func loadEntries(query: TopicsQuery) {
        self.query = query
        self.pagingQuery = TopicsPagingQuery.init(query)
        self.topics.removeAll()
        executeQuery(success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
    }

    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.topics.removeAll()
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
        return self.topics.count
    }

    func entry(at: Int) -> Topic {
        return self.topics[at]
    }

    func findTopic(_ topicId: String) -> Topic? {
        return self.topics.filter {
            return $0.id == topicId
        }.first
    }

    func followTopic(_ topicId: String) {
        if let topic = findTopic(topicId), let topicIndex = self.topics.firstIndex(of: topic) {
            let query = FollowQuery.topics([topicId])
            if topic.isFollowedByMe {
                Communities.unfollow(query, success: { _ in
                    PrivateTopicBuilder.updateTopic(topic: topic, isFollowed: false)
                    self.topicUnfollowed?(topicIndex)
                }) { error in
                    self.onError?(error)
                }

            } else {
                Communities.follow(query, success: { _ in
                    PrivateTopicBuilder.updateTopic(topic: topic, isFollowed: true)
                    self.topicFollowed?(topicIndex)
                }) { error in
                    self.onError?(error)
                }
            }
        }

    }

    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        Communities.topics(self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.topics.append(contentsOf: result.topics)
            success?()
        }) { error in
            failure?(error)
        }
    }

}
