//
//  AddGroupMemberModel.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 14/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

class AddGroupMemberModel {
    
    var onMemberAdded: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    let groupId: String
    
    required init(groupId: String) {
        self.groupId = groupId
    }

    func addMember(userId: String, providerId: String? = nil, role: Role, status: MemberStatus) {
        let userIdList = providerId == nil ? UserIdList.create([userId]) : UserIdList.create(provider: providerId!, ids: [userId])
        
        let query = AddGroupMembersQuery(id: self.groupId, userIds: userIdList).withMemberStatus(status).withRole(role)
        Communities.addGroupMembers(query, success: { [weak self] _ in
            self?.onMemberAdded?()
            }, failure: { [weak self] error in
                self?.onError?(error)
        })
    }
}
