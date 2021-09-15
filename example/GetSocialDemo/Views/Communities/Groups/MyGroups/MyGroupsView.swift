//
//  TopicsView.swift
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import UIKit
import GetSocialUI

class MyGroupsView {

    var viewController: MyGroupsViewController
    var showGroupMembersOfGroup: ((String, Role) -> Void)?
	var showPolls: ((String) -> Void)?
	var showAnnouncementsPolls: ((String) -> Void)?

    init() {
        self.viewController = MyGroupsViewController()
        self.viewController.delegate = self
    }
}

extension MyGroupsView: MyGroupTableViewControllerDelegate {
    func onEditGroup(_ group: Group) {
        let vc = CreateGroupViewController(group)
        self.viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    func onShowFeed(_ ofGroupId: String) {
        let query = ActivitiesQuery.inGroup(ofGroupId)
        let activitiesView = GetSocialUIActivityFeedView.init(for: query)
        activitiesView.setAvatarClickHandler { user in
            let mainVC = self.viewController.parent?.parent as? MainViewController
            mainVC?.didClick(on: user)
        }
        activitiesView.setActionHandler { action in
            let mainVC = self.viewController.parent?.parent as? MainViewController
            mainVC?.handle(action)
        }
        activitiesView.setMentionClickHandler { mention in
            let mainVC = self.viewController.parent?.parent as? MainViewController
            if mention == GetSocialUI_Shortcut_App {
                mainVC?.showAlert(withText: "Application mention clicked")
            } else {
                let userId = UserId.create(mention!)
                Communities.user(userId, success: { user in
                    mainVC?.didClick(on: user)
                }, failure: { error in
                    print("Failed to get user, error: \(error)")
                })
            }
        }
        activitiesView.setTagClickHandler { tag in
            let mainVC = self.viewController.parent?.parent as? MainViewController
            mainVC?.showAlert(withText: "Clicked on tag [\(tag!)]")
        }
        if let mainVC = self.viewController.parent?.parent as? MainViewController {
            if mainVC.showCustomErrorMessages {
                activitiesView.setCustomErrorMessageProvider { (errorCode, errorMessage) -> String? in
                    if errorCode == ErrorCode.ActivityRejected {
                        return "Be careful what you say :)"
                    }
                    return errorMessage
                }
            }
        }
		activitiesView.setHandlerForViewOpen({
			// do nothing here
		}, close: {
			self.viewController.viewDidAppear(true)
		})

        GetSocialUI.show(activitiesView)
    }

	func onShowPolls(_ inGroup: String) {
		self.showPolls?(inGroup)
	}

	func onShowAnnouncementsPolls(_ inGroup: String) {
		self.showAnnouncementsPolls?(inGroup)
	}

    func onPostActivity(_ groupId: String) {
        let target = PostActivityTarget.group(groupId)
        let vc = UIStoryboard.viewController(forName: "PostActivity", in: .activityFeed) as! PostActivityViewController
        vc.postTarget = target
        self.viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    func onShowGroupMembers(_ ofGroupId: String, role: Role) {
        self.showGroupMembersOfGroup?(ofGroupId, role)
    }

	func onCreatePoll(_ groupId: String) {
		let target = PostActivityTarget.group(groupId)
		let vc = CreatePollView(target)
		self.viewController.navigationController?.pushViewController(vc, animated: true)
	}

}
