//
//  GenericModel.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation

class MyGroupsModel {

    var onInitialDataLoaded: (() -> Void)?
    var onDidOlderLoad: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var groupFollowed: ((Int) -> Void)?
    var groupUnfollowed: ((Int) -> Void)?
    var onGroupDeleted: ((Int) -> Void)?
    var onGroupLeft: ((Int) -> Void)?
    var onInviteAccepted: ((Int) -> Void)?

    var pagingQuery: GroupsPagingQuery?
    var query: GroupsQuery?

    var groups: [Group] = []
    var nextCursor: String = ""

    func loadEntries() {
        self.query = GroupsQuery.all().byMember(UserId.currentUser())
        self.pagingQuery = GroupsPagingQuery.init(self.query!)
        self.groups.removeAll()
        executeQuery(success: {
            self.onInitialDataLoaded?()
        }, failure: onError)
    }

    func loadNewer() {
        self.pagingQuery?.nextCursor = ""
        self.groups.removeAll()
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
        return self.groups.count
    }

    func entry(at: Int) -> Group {
        return self.groups[at]
    }

    func findGroup(_ groupId: String) -> Group? {
        return self.groups.filter {
            return $0.id == groupId
        }.first
    }

    func leaveGroup(_ groupId: String) {
        guard let currentUserId = GetSocial.currentUser()?.userId else {
            self.onError?("Could not get current user")
            return
        }
        var groupIndex: Int?
        for (index, group) in self.groups.enumerated() {
            if group.id == groupId {
                groupIndex = index
            }
        }
        
        let query = RemoveGroupMembersQuery.users(UserIdList.create([currentUserId]), from: groupId)
        Communities.removeGroupMembers(query, success: { [weak self] in
            self?.groups.remove(at: groupIndex!)
            self?.onGroupLeft?(groupIndex!)
        }, failure: { [weak self] error in
            self?.onError?(error.localizedDescription)
        })
    }

    func acceptInvite(_ groupId: String, membership: Membership) {
        var groupIndex: Int?
        for (index, group) in self.groups.enumerated() {
            if group.id == groupId {
                groupIndex = index
            }
        }
        let query = JoinGroupQuery.init(groupId: groupId).withInvitationToken(membership.invitationToken!)
        Communities.joinGroup(query, success: { [weak self] members in
            Communities.group(groupId, success: { group in
                self?.groups[groupIndex!] = group
                self?.onInviteAccepted?(groupIndex!)
            }, failure: { error in
                self?.onError?(error.localizedDescription)
            })
        }, failure: { [weak self] error in
            self?.onError?(error.localizedDescription)
        })
    }


    func followGroup(_ groupId: String) {
        if let group = findGroup(groupId), let groupIndex = self.groups.firstIndex(of: group) {
            let query = FollowQuery.groups([groupId])
            if group.isFollowedByMe {
                Communities.unfollow(query, success: { _ in
                    PrivateGroupBuilder.updateGroup(group: group, isFollowed: false)
                    self.groupUnfollowed?(groupIndex)
                }) { error in
                    self.onError?(error.localizedDescription)
                }

            } else {
                Communities.follow(query, success: { _ in
                    PrivateGroupBuilder.updateGroup(group: group, isFollowed: true)
                    self.groupFollowed?(groupIndex)
                }) { error in
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
    
    func deleteGroup(_ groupId: String) {
        var groupIndex: Int?
        for (index, group) in self.groups.enumerated() {
            if group.id == groupId {
                groupIndex = index
            }
        }
        Communities.removeGroups([groupId], success: { [weak self] in
                self?.groups.remove(at: groupIndex!)
                self?.onGroupDeleted?(groupIndex!)
            }, failure: { [weak self] error in
                self?.onError?(error.localizedDescription)
        })
    }

    private func executeQuery(success: (() -> Void)?, failure: ((String) -> Void)?) {
        Communities.groups(self.pagingQuery!, success: { result in
            self.nextCursor = result.nextCursor
            self.groups.append(contentsOf: result.groups)
            success?()
        }) { error in
            failure?(error.localizedDescription)
        }
    }

}
