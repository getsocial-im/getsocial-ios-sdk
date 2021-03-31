//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialUI

class GroupMembersView {

    var viewController: GroupMembersViewController
    var model: GroupMembersModel
    var groupId: String? {
        didSet {
            self.viewController.groupId = self.groupId
        }
    }
    var currentUserRole: Role? {
        didSet {
            self.viewController.currentUserRole = self.currentUserRole
        }
    }
    init() {
        self.model = GroupMembersModel()
        self.viewController = GroupMembersViewController(self.model)
    }
}
