//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class FollowersModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onDidFollowersCount: ((Int) -> Void)?
    var onFriendStatusUpdated: ((Int) -> Void)?

    var pagingQuery: FollowersPagingQuery?
    var query: FollowersQuery?

    var users: [User] = []
    var nextCursor: String = ""
    var friendsStatuses: [String: Bool] = [:]

    func loadFollowersCount(query: FollowersQuery) {
        Communities.followersCount(query: query, success: { count in
            self.onDidFollowersCount?(count)
        }) { error in
            self.onError?(error)
        }
    }

    func loadEntries(query: FollowersQuery) {
        self.query = query
        self.pagingQuery = FollowersPagingQuery.init(query: query)
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.users.removeAll()
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func loadOlder() {
        if self.nextCursor.count == 0 {
            onDidOlderLoad?()
        }
        self.pagingQuery?.nextCursor = self.nextCursor
        executeQuery(success: onDidOlderLoad, failure: onError)
    }

    func numberOfEntries() -> Int {
        return self.users.count
    }

    func entry(at: Int) -> User {
        return self.users[at]
    }

    func find(_ id: String) -> User? {
        return self.users.filter {
            return $0.userId == id
        }.first
    }

    private func executeQuery(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        Communities.followers(query: self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.users.append(contentsOf: result.users)
            self.loadFriendsStatus(of: result.users, success: success)
        }) { error in
            failure?(error)
        }
    }

    func updateFriendsStatus(of userId: String, newStatus: Bool) {
        if let user = find(userId), let userIndex = self.users.firstIndex(of: user) {
            let userIdList = UserIdList.users(ids: [userId])
            if newStatus {
                Communities.addFriends(ids: userIdList, success: { result in
                    self.friendsStatuses[userId] = newStatus
                    self.onFriendStatusUpdated?(userIndex)
                }) { error in
                    self.onError?(error)
                }
            } else {
                Communities.removeFriends(ids: userIdList, success: { result in
                    self.friendsStatuses[userId] = newStatus
                    self.onFriendStatusUpdated?(userIndex)
                }) { error in
                    self.onError?(error)
                }
            }
        }
    }

    private func loadFriendsStatus(of users: [User], success: (() -> Void)?) {
        let userIds = users.map {
            return $0.userId
        }
        Communities.areFriends(ids: UserIdList.users(ids: userIds), success: { result in
            result.forEach {
                if !self.friendsStatuses.keys.contains($0.key) {
                    self.friendsStatuses[$0.key] = $0.value
                }
            }
            success?()
        }) { error in
            self.onError?(error)
        }
    }

}
