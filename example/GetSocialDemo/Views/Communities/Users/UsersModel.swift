//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class UsersModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onFriendStatusUpdated: ((Int) -> Void)?
    var onFollowStatusUpdated: ((Int) -> Void)?

    var pagingQuery: UsersPagingQuery?
    var query: UsersQuery?

    var users: [User] = []
    var nextCursor: String = ""
    var friendsStatuses: [String: Bool] = [:]
    var followStatuses: [String: Bool] = [:]
    var followersCount: [String: Int] = [:]

    func loadEntries(query: UsersQuery) {
        self.query = query
        self.pagingQuery = UsersPagingQuery.init(query)
        self.users.removeAll()
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.users.removeAll()
        executeQuery(success: onInitialDataLoaded, failure: onError)
    }

    func loadOlder() {
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
        Communities.users(self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.users.append(contentsOf: result.users)
            self.loadFriendsStatus(of: result.users, success: {
                self.loadFollowStatus(of: result.users, success: {
                    self.loadFollowersCount(of: result.users, success: {
                        success?()
                    })
                })
            })
        }) { error in
            failure?(error)
        }
    }

    private func loadFollowStatus(of users: [User], success: (() -> Void)?) {
        if users.count == 0 {
            success?()
            return
        }
        let userIds = users.map {
            return $0.userId
        }
        let followQuery = FollowQuery.users(UserIdList.create(userIds))
        Communities.isFollowing(UserId.currentUser(), query: followQuery, success: { result in
            if result.isEmpty {
                userIds.forEach {
                    self.followStatuses.removeValue(forKey: $0)
                }
            } else {
                result.forEach {
                    if !self.followStatuses.keys.contains($0.key) {
                        self.followStatuses[$0.key] = $0.value
                    }
                }
            }
            success?()
        }, failure: { error in
            self.onError?(error)
        })
    }

    private func loadFollowersCount(of users: [User], success: (() -> Void)?) {
        if users.count == 0 {
            success?()
            return
        }
        users.forEach { user in
            let followersQuery = FollowersQuery.ofUser(UserId(user.userId))
            Communities.followersCount(followersQuery, success: { followersCount in
                self.followersCount[user.userId] = followersCount
                success?()
            }, failure: { error in
                self.onError?(error)
            })
        }
    }

    private func loadFriendsStatus(of users: [User], success: (() -> Void)?) {
        if users.count == 0 {
            success?()
            return
        }
        let userIds = users.map {
            return $0.userId
        }
        Communities.areFriends(UserIdList.create(userIds), success: { result in
            if result.isEmpty {
                userIds.forEach {
                    self.friendsStatuses.removeValue(forKey: $0)
                }
            } else {
                result.forEach {
                    if !self.friendsStatuses.keys.contains($0.key) {
                        self.friendsStatuses[$0.key] = $0.value
                    }
                }
            }
            success?()
        }) { error in
            self.onError?(error)
        }
    }

    func updateFriendsStatus(of userId: String, newStatus: Bool) {
        if let user = find(userId), let userIndex = self.users.firstIndex(of: user) {
            let userIdList = UserIdList.create([userId])
            if newStatus {
                Communities.addFriends(userIdList, success: { result in
                    self.loadFriendsStatus(of: [user], success: {
                        self.loadFollowStatus(of: [user], success: {
                            self.loadFollowersCount(of: [user], success: {
                                self.onFriendStatusUpdated?(userIndex)
                            })
                        })
                    })
                }) { error in
                    self.onError?(error)
                }
            } else {
                Communities.removeFriends(userIdList, success: { result in
                    self.loadFriendsStatus(of: [user], success: {
                        self.loadFollowStatus(of: [user], success: {
                            self.loadFollowersCount(of: [user], success: {
                                self.onFriendStatusUpdated?(userIndex)
                            })
                        })
                    })
                }) { error in
                    self.onError?(error)
                }
            }
        }
    }

    func updateFollowStatus(of userId: String, newStatus: Bool) {
        if let user = find(userId), let userIndex = self.users.firstIndex(of: user) {
            let userIdList = UserIdList.create([userId])
            if newStatus {
                Communities.follow(FollowQuery.users(userIdList), success: { _ in
                    self.loadFriendsStatus(of: [user], success: {
                        self.loadFollowStatus(of: [user], success: {
                            self.loadFollowersCount(of: [user], success: {
                                self.onFollowStatusUpdated?(userIndex)
                            })
                        })
                    })
                }) { error in
                    self.onError?(error)
                }
            } else {
                Communities.unfollow(FollowQuery.users(userIdList), success: { _ in
                    self.loadFriendsStatus(of: [user], success: {
                        self.loadFollowStatus(of: [user], success: {
                            self.loadFollowersCount(of: [user], success: {
                                self.onFollowStatusUpdated?(userIndex)
                            })
                        })
                    })
                }) { error in
                    self.onError?(error)
                }
            }
        }
    }
    
    func blockUser(id userId: String) {
        if let user = find(userId), let userIndex = self.users.firstIndex(of: user) {
            let userIdList = UserIdList.create([userId])
            
            Communities.blockUsers(userIdList, success: {
                self.onFollowStatusUpdated?(userIndex)
            }, failure: { error in
                self.onError?(error)
            })
        }
    }
    
    func unblockUser(id userId: String) {
        if let user = find(userId), let userIndex = self.users.firstIndex(of: user) {
            let userIdList = UserIdList.create([userId])
            
            Communities.unblockUsers(userIdList, success: {
                self.onFollowStatusUpdated?(userIndex)
            }, failure: { error in
                self.onError?(error)
            })
        }
    }

}
