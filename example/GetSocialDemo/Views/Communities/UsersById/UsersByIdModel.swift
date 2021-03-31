//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class UsersByIdModel {

    var onOperationFinished: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onRowAdded: ((Int) -> Void)?

    var userIds: [String] = []

    func addRow() {
        self.userIds.append("428131057698968235")
        self.onRowAdded?(self.userIds.count - 1)
    }

    func findUsers(providerId: String?) {
        self.filterUserIds()

        Communities.users(self.createUserIdList(providerId: providerId), success: { users in
            self.onOperationFinished?(String(describing: users))
        }, failure: { error in
            self.onError?(error)
        })
    }

    func addFriends(providerId: String?) {
        self.filterUserIds()

        Communities.addFriends(self.createUserIdList(providerId: providerId), success: { result in
            self.onOperationFinished?("Friends added, you have now [\(result)] friends")
        }, failure: { error in
            self.onError?(error)
        })
    }

    func areFriends(providerId: String?) {
        self.filterUserIds()

        Communities.areFriends(self.createUserIdList(providerId: providerId), success: { result in
            self.onOperationFinished?(String(describing: result))
        }, failure: { error in
            self.onError?(error)
        })
    }

    func removeFriends(providerId: String?) {
        self.filterUserIds()

        Communities.removeFriends(self.createUserIdList(providerId: providerId), success: { result in
            self.onOperationFinished?("Friends removed, you have now [\(result)] friends")
        }, failure: { error in
            self.onError?(error)
        })
    }

    func setFriends(providerId: String?) {
        self.filterUserIds()

        Communities.setFriends(self.createUserIdList(providerId: providerId), success: { result in
            self.onOperationFinished?("[\(result)] friends was set")
        }, failure: { error in
            self.onError?(error)
        })
    }

    func followUsers(providerId: String?) {
        self.filterUserIds()

        Communities.follow(FollowQuery.users(self.createUserIdList(providerId: providerId)), success: { _ in
            self.onOperationFinished?("Users are followed")
        }, failure: { error in
            self.onError?(error)
        })
    }

    func unfollowUsers(providerId: String?) {
        self.filterUserIds()

        Communities.unfollow(FollowQuery.users(self.createUserIdList(providerId: providerId)), success: { _ in
            self.onOperationFinished?("Users are unfollowed.")
        }, failure: { error in
            self.onError?(error)
        })
    }

    func isFollowingUsers(providerId: String?) {
        self.filterUserIds()

        Communities.isFollowing(UserId.currentUser(), query: FollowQuery.users(self.createUserIdList(providerId: providerId)), success: { result in
            self.onOperationFinished?("\(result)")
        }, failure: { error in
            self.onError?(error)
        })
    }

    func sendNotification(providerId: String?) {
        self.filterUserIds()

        let content = NotificationContent.withText("Hello from SDK7")

        Notifications.send(content, target: SendNotificationTarget.users(self.createUserIdList(providerId: providerId)), success: {
            self.onOperationFinished?("Notification was sent")
        }) { error in
            self.onError?(error)
        }
    }

    internal func createUserIdList(providerId: String?) -> UserIdList {
        return (providerId == nil || providerId!.count == 0) ? UserIdList.create(userIds) : UserIdList.create(provider: providerId!, ids: userIds)
    }

    internal func filterUserIds()  {
        // remove empty rows
        userIds = userIds.filter {
            $0.count > 0
        }
    }

    func numberOfEntries() -> Int {
        return self.userIds.count
    }

    func entry(at: Int) -> String {
        return self.userIds[at]
    }

    func updateEntry(at: Int, value: String) {
        self.userIds[at] = value
    }

}
