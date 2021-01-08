//
//  GroupMembersModel.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 09/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

class GroupMembersModel {
    var groupMembers: [GroupMember] = []
    
    var onMemberApproved: (() -> Void)?
    var onMembersRetrieved: (() -> Void)?
    var onMemberRemoved: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    func loadMembers(_ query: MembersQuery) {
        let pagingQuery = MembersPagingQuery(query)
        Communities.membersOfGroup(pagingQuery, success: { [weak self] result in
            self?.groupMembers = result.members
            self?.onMembersRetrieved?()
            }, failure: { [weak self] error in
                self?.onError?(error)
        })
    }
    
    func findMember(_ memberId: String) -> GroupMember? {
        return self.groupMembers.filter {
            return $0.userId == memberId
        }.first
    }

    func approveMember(_ groupMember: GroupMember, groupId: String) {
        let query = UpdateGroupMembersQuery.init(id: groupId, userIds: UserIdList.create([groupMember.userId]))
            .withRole(.member)
            .withMemberStatus(.member)

        Communities.updateGroupMembers(query, success: { [weak self] members in
            self?.onMemberApproved?()
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }

    func removeMember(_ groupMember: GroupMember, groupId: String) {
        let query = RemoveGroupMembersQuery.users(UserIdList.create([groupMember.userId]), from: groupId)
        Communities.removeGroupMembers(query, success: { [weak self] in
            self?.onMemberRemoved?()
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
}
