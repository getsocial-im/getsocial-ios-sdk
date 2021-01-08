//
//  CreateGroupModel.swift
//  GetSocialInternalDemo
//
//  Created by Gábor Vass on 09/10/2020.
//  Copyright © 2020 GrambleWorld. All rights reserved.
//

import Foundation

class CreateGroupModel {
    var onGroupCreated: ((Group) -> Void)?
    var onGroupUpdated: ((Group) -> Void)?
    var onError: ((String) -> Void)?
    var oldGroupId: String?
    
    required init(oldGroupId: String? = nil) {
        self.oldGroupId = oldGroupId
    }
    
    func createGroup(_ content: GroupContent) {
        if let groupId = self.oldGroupId {
            Communities.updateGroup(groupId, content: content, success: { [weak self] group in
                self?.onGroupUpdated?(group)
            }, failure: { [weak self] error in
                    self?.onError?("Failed to update group, error: \(error)")
            })
        } else {
            Communities.createGroup(content, success: { [weak self] group in
                self?.onGroupCreated?(group)
            }) { [weak self] error in
                self?.onError?("Failed to create group, error: \(error)")
            }
        }
    }
}
