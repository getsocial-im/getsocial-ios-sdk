//
//  CommunitiesObjCHelper.swift
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

import Foundation
import UIKit

@objcMembers
public class CommunitiesHelper: NSObject {
    
    public static func showTopics(navigationController: UINavigationController) {
        let topicsView = TopicsView()
        navigationController.pushViewController(topicsView.viewController, animated: true)

        topicsView.showFollowersOfTopic = { topicId in
            let followersView = FollowersView()
            followersView.query = FollowersQuery.ofTopic(topicId)
            followersView.showFollowersOfUser = { user, count in
                let followersView = FollowersView()
                followersView.query = FollowersQuery.ofUser(user)
                navigationController.pushViewController(followersView.viewController, animated: true)
            }
            navigationController.pushViewController(followersView.viewController, animated: true)
        }
		topicsView.showPolls = { topicId in
			self.showPolls(navigationController: navigationController, query: ActivitiesQuery.inTopic(topicId))
		}
		topicsView.showFeed = { topicId in
			let view = ActivitiesView(ActivitiesQuery.inTopic(topicId))
			navigationController.pushViewController(view.viewController, animated: true)
		}
		topicsView.showAnnouncementsPolls = { topicId in
			self.showAnnouncementPolls(navigationController: navigationController, query: AnnouncementsQuery.inTopic(topicId))
		}
    }

    public static func showGroups(navigationController: UINavigationController) {
        let groupsView = GroupsView()
        navigationController.pushViewController(groupsView.viewController, animated: true)

        groupsView.showGroupMembersOfGroup = { (groupId, role) in
            let groupMembersView = GroupMembersView()
            groupMembersView.groupId = groupId
            groupMembersView.currentUserRole = role
            
            navigationController.pushViewController(groupMembersView.viewController, animated: true)
        }
		groupsView.showPolls = { groupId in
			self.showPolls(navigationController: navigationController, query: ActivitiesQuery.inGroup(groupId))
		}
		groupsView.showAnnouncementsPolls = { groupId in
			self.showAnnouncementPolls(navigationController: navigationController, query: AnnouncementsQuery.inGroup(groupId))
		}
		groupsView.showPlainFeed = { groupId in
			let view = ActivitiesView(ActivitiesQuery.inGroup(groupId))
			navigationController.pushViewController(view.viewController, animated: true)
		}

    }

    public static func showFollowers(navigationController: UINavigationController) {
        let followersView = FollowersView()
        navigationController.pushViewController(followersView.viewController, animated: true)

        followersView.showFollowersOfUser = { userId, followersCount in
            let followersView = FollowersView()
            followersView.followersCount = followersCount
            followersView.query = FollowersQuery.ofUser(userId)
            navigationController.pushViewController(followersView.viewController, animated: true)
        }
    }

    public static func showUsers(navigationController: UINavigationController) {
        let usersView = UsersView()
        navigationController.pushViewController(usersView.viewController, animated: true)

        usersView.showFollowersOfUser = { userId, followersCount in
            let followersView = FollowersView()
            followersView.query = FollowersQuery.ofUser(userId)
            followersView.followersCount = followersCount
            navigationController.pushViewController(followersView.viewController, animated: true)
        }
        usersView.showFollowingsOfUser = { userId in
            let followingsView = UsersView()
            followingsView.query = UsersQuery.followedBy(userId)
            navigationController.pushViewController(followingsView.viewController, animated: true)

        }
    }

    public static func showUsersById(navigationController: UINavigationController) {
        let usersByIdView = UsersByIdView()
        navigationController.pushViewController(usersByIdView.viewController, animated: true)
    }

    public static func showTags(navigationController: UINavigationController) {
        let tagsView = TagsView()
        navigationController.pushViewController(tagsView.viewController, animated: true)
    }

	public static func showReactions(navigationController: UINavigationController) {
		let feedView = FeedView()
		navigationController.pushViewController(feedView.viewController, animated: true)
	}

    public static func showCreateGroup(navigationController: UINavigationController) {
        let createGroupView = CreateGroupViewController()
        navigationController.pushViewController(createGroupView, animated: true)
    }

    public static func showGroupMembers(navigationController: UINavigationController) {
        let membersView = GroupMembersView()
        navigationController.pushViewController(membersView.viewController, animated: true)
    }

    public static func showMyGroups(navigationController: UINavigationController) {
        let myGroups = MyGroupsView()
        myGroups.showGroupMembersOfGroup = { (groupId, role) in
            let groupMembersView = GroupMembersView()
            groupMembersView.groupId = groupId
            groupMembersView.currentUserRole = role
            
            navigationController.pushViewController(groupMembersView.viewController, animated: true)
        }
		myGroups.showPolls = { groupId in
			self.showPolls(navigationController: navigationController, query: ActivitiesQuery.inGroup(groupId))
		}
		myGroups.showAnnouncementsPolls = { groupId in
			self.showAnnouncementPolls(navigationController: navigationController, query: AnnouncementsQuery.inGroup(groupId))
		}
        navigationController.pushViewController(myGroups.viewController, animated: true)
    }

    public static func showChatMessages(navigationController: UINavigationController, chatId: String) {
        GetSocialUI.closeView(false)
        Communities.chat(ChatId.create(chatId), success: { chat in
            let chatMessagesView = ChatMessagesView(chat)
            navigationController.pushViewController(chatMessagesView.viewController, animated: true)
        }, failure: { error in
            print("Failed to get chat, error: \(error)")
        })
    }

    public static func showChatMessages(navigationController: UINavigationController, userId: UserId) {
        let chatMessagesView = ChatMessagesView(userId)
        navigationController.pushViewController(chatMessagesView.viewController, animated: true)
    }


    public static func showChats(navigationController: UINavigationController) {
		let chatsView = ChatsView()
        chatsView.onShowChat = { chatId in
            let chatMessagesView = ChatMessagesView(chatId)
            navigationController.pushViewController(chatMessagesView.viewController, animated: true)
        }
        navigationController.pushViewController(chatsView.viewController, animated: true)
    }

	public static func showCreatePoll(navigationController: UINavigationController, target: PostActivityTarget) {
		let createPollView = CreatePollView(target)
		navigationController.pushViewController(createPollView, animated: true)
	}

	public static func showAnnouncementPolls(navigationController: UINavigationController, query: AnnouncementsQuery) {
		let pollsView = PollsView(query)
		pollsView.showVote = { activity in
			self.showVote(navigationController: navigationController, activity: activity)
		}
		pollsView.showAllVotes = { activity in
			self.showAllVotes(navigationController: navigationController, activity: activity)
		}
		navigationController.pushViewController(pollsView.viewController, animated: true)
	}

	public static func showPolls(navigationController: UINavigationController, query: ActivitiesQuery) {
		let pollsView = PollsView(query)
		pollsView.showVote = { activity in
			self.showVote(navigationController: navigationController, activity: activity)
		}
		pollsView.showAllVotes = { activity in
			self.showAllVotes(navigationController: navigationController, activity: activity)
		}
		navigationController.pushViewController(pollsView.viewController, animated: true)
	}

	public static func showVote(navigationController: UINavigationController, activity: Activity) {
		let voteView = VoteViewController(activity.id)
		navigationController.pushViewController(voteView, animated: true)
	}

	public static func showAllVotes(navigationController: UINavigationController, activity: Activity) {
		let voteView = VoteListViewController(activity.id)
		navigationController.pushViewController(voteView, animated: true)
	}

	public static func showTimeline(navigationController: UINavigationController) {
		let view = ActivitiesView(ActivitiesQuery.timeline())
		navigationController.pushViewController(view.viewController, animated: true)
	}

	public static func showUserFeed(navigationController: UINavigationController) {
		let view = ActivitiesView(ActivitiesQuery.feedOf(UserId.currentUser()))
		navigationController.pushViewController(view.viewController, animated: true)
	}

}

enum GetSocialDemoError: Error {
	case missingParameter(String)
}
