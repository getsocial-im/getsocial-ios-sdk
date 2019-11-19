/*
 *    	Copyright 2015-2019 GetSocial B.V.
 *
 *	Licensed under the Apache License, Version 2.0 (the "License");
 *	you may not use this file except in compliance with the License.
 *	You may obtain a copy of the License at
 *
 *    	http://www.apache.org/licenses/LICENSE-2.0
 *
 *	Unless required by applicable law or agreed to in writing, software
 *	distributed under the License is distributed on an "AS IS" BASIS,
 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *	See the License for the specific language governing permissions and
 *	limitations under the License.
 */

#import "MainViewController.h"
#import <UIKit/UIKit.h>
#import "ActivityIndicatorViewController.h"
#import "ConsoleViewController.h"
#import "Constants.h"
#import "FriendsViewController.h"
#import "IAPViewController.h"
#import "MainNavigationController.h"
#import "MenuItem.h"
#import "NewFriendViewController.h"
#import "NotificationsViewController.h"
#import "PostActivityViewController.h"
#import "UISimpleAlertViewController.h"
#import "UIViewController+GetSocial.h"
#import "UserIdentityUtils.h"

#import <GetSocial/GetSocial.h>
#import <GetSocialUI/GetSocialUI.h>

#import "GetSocialFBMessengerInvitePlugin.h"
#import "GetSocialFacebookSharePlugin.h"
#import "GetSocialInstagramStoriesInviteChannel.h"
#import "GetSocialKakaoTalkInvitePlugin.h"
#import "GetSocialVKInvitePlugin.h"
#if DISABLE_TWITTER != 1
#import "GetSocialTwitterInvitePlugin.h"
#endif
#import "MenuTableViewController.h"
#import "MessagesController.h"
#import "PushNotificationView.h"
#import "UIImage+GetSocial.h"
#import "UIStoryboard+GetSocial.h"

#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <GetSocial/GetSocialInstallPlatform.h>
#import <UserNotifications/UserNotifications.h>

#define GSLogInfo(bShowAlert, bShowConsole, sMessage, ...)                \
    [self log:LogLevelInfo                                                \
            context:NSStringFromSelector(_cmd)                            \
            message:[NSString stringWithFormat:(sMessage), ##__VA_ARGS__] \
          showAlert:bShowAlert                                            \
        showConsole:bShowConsole]

#define GSLogWarning(bShowAlert, bShowConsole, sMessage, ...)             \
    [self log:LogLevelWarning                                             \
            context:NSStringFromSelector(_cmd)                            \
            message:[NSString stringWithFormat:(sMessage), ##__VA_ARGS__] \
          showAlert:bShowAlert                                            \
        showConsole:bShowConsole]

#define GSLogError(bShowAlert, bShowConsole, sMessage, ...)               \
    [self log:LogLevelError                                               \
            context:NSStringFromSelector(_cmd)                            \
            message:[NSString stringWithFormat:(sMessage), ##__VA_ARGS__] \
          showAlert:bShowAlert                                            \
        showConsole:bShowConsole]

#define ExecuteBlock(block, ...) \
    if (block) block(##__VA_ARGS__)

#define MAX_WIDTH 500.f
#define MAX_HEIGHT 500.f

NSString *const kCustomProvider = @"custom";

@interface MainViewController ()<UINavigationControllerDelegate, PostActivityVCDelegate>

@property(nonatomic, strong) ParentMenuItem *uiCustomizationMenu;
@property(nonatomic, strong) ParentMenuItem *languageMenu;
@property(nonatomic, strong) ParentMenuItem *smartInvitesMenu;
@property(nonatomic, strong) ParentMenuItem *activitiesMenu;
@property(nonatomic, strong) ParentMenuItem *settingsMenu;
@property(nonatomic, strong) ParentMenuItem *userAuthenticationMenu;

@property(nonatomic, strong) FBSDKLoginManager *facebookSdkManager;

@property(nonatomic, strong) ActionableMenuItem *friendsMenu;
@property(nonatomic, strong) ParentMenuItem *notificationsMenu;
@property(nonatomic, strong) UIImagePickerController *avatarImagePicker;
@property(nonatomic, strong) CheckableMenuItem *pushNotificationsEnabledMenu;
@property(nonatomic, strong) CheckableMenuItem *statusBarMenuItem;
@property(nonatomic, assign) BOOL statusBarHidden;
@property(nonatomic, strong) NSString *chatIdToShow;
@property(nonatomic, strong) NSString *userIdToShow;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateVersionInfo];

    [self log:LogLevelInfo context:nil message:self.versionLabel.text showAlert:NO showConsole:NO];

    [self setUpGetSocial];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)setUpGetSocial
{
    [GetSocial setPushNotificationTokenHandler:^(NSString *_Nonnull deviceToken) {
        [[ConsoleViewController sharedController] log:LogLevelInfo
                                              message:[NSString stringWithFormat:@"Device Push Token: %@", deviceToken]
                                              context:@"PushNotificationHandler"];
    }];
    [GetSocial setNotificationHandler:^BOOL(GetSocialNotification *notification, BOOL wasClicked) {
        return [self handleNotification:notification withContext:@{ @"wasClicked" : @(wasClicked) }];
    }];
    [GetSocialUser setOnUserChangedHandler:^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        [self updateFriendsCount];
    }];

    [GetSocial executeWhenInitialized:^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        if (self.chatIdToShow)
        {
            [self showChatView];
        }
        else if (self.userIdToShow)
        {
            [self showNewFriend];
        }
        else
        {
            [self checkReferralData];
        }

    }];

    [self registerInviteChannelPlugins];
}

- (BOOL)handleNotification:(GetSocialNotification *)notification withContext:(NSDictionary *)context
{
    if (context[@"actionId"])
    {
        [self handleNotification:notification withAction:context[@"actionId"]];
        return YES;
    }
    if ([notification.notificationAction.type isEqualToString:GetSocialActionAddFriend])
    {
        NSMutableArray<NSString *> *buttons = @[].mutableCopy;
        for (GetSocialActionButton *button in notification.actionButtons)
        {
            [buttons addObject:button.title];
        }
        UISimpleAlertViewController *alertViewController = [[UISimpleAlertViewController alloc] initWithTitle:notification.title
                                                                                                      message:notification.text
                                                                                            cancelButtonTitle:@"Dismiss"
                                                                                            otherButtonTitles:buttons];
        [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (didCancel)
            {
                return;
            }
            [self handleNotification:notification withAction:notification.actionButtons[selectedIndex].actionId];
        }];
        return YES;
    }
    if ([notification.notificationAction.type isEqualToString:@"open_chat_message"])
    {
        self.chatIdToShow = notification.notificationAction.data[@"open_messages_for_id"];
        if (GetSocial.isInitialized)
        {
            [self showChatView];
        }
        return YES;
    }
    if (![context[@"wasClicked"] boolValue])
    {
        NSString *title = notification.title.length > 0 ? notification.title : @"Push Notification Received";
        [PushNotificationView showNotificationWithTitle:title andMessage:notification.text];
        return YES;
    }

    return [self handleAction:notification.notificationAction];
}

- (void)showChatView
{
    __block MessagesController *mc = nil;
    [GetSocial userWithId:self.chatIdToShow
                  success:^(GetSocialPublicUser *publicUser) {
                      if ([self.mainNavigationController.topViewController isKindOfClass:[MessagesController class]])
                      {
                          mc = (MessagesController *)self.mainNavigationController.topViewController;
                      }
                      else
                      {
                          mc = [UIStoryboard viewControllerForName:@"Messages" inStoryboard:GetSocialStoryboardMessages];
                      }
                      if ([mc.receiver.userId isEqualToString:publicUser.userId])
                      {
                          [mc updateMessages];
                      }
                      else
                      {
                          [mc setReceiver:publicUser];
                          [self.mainNavigationController pushViewController:mc animated:YES];
                      }
                      self.chatIdToShow = nil;
                  }
                  failure:^(NSError *error){

                  }];
}

- (void)handleNotification:(GetSocialNotification *)notification withAction:(NSString *)actionId
{
    GetSocialAction *action = notification.notificationAction;
    GetSocialNotificationStatus status = GetSocialNotificationStatusConsumed;

    if ([actionId isEqualToString:GetSocialActionIdConsume])
    {
        [GetSocial processAction:action];
        if ([action.type isEqualToString:GetSocialActionAddFriend])
        {
            NSString *userName = action.data[@"user_name"];
            [self showAlertWithText:[NSString stringWithFormat:@"%@ added to friends.", userName]];
        }
    }
    else if ([actionId isEqualToString:GetSocialActionIdIgnore])
    {
        status = GetSocialNotificationStatusIgnored;
    }
    [GetSocialUser setNotificationsStatus:@[ notification.notificationId ]
        status:status
        success:^{
            NSLog(@"Successfully updated notification");
        }
        failure:^(NSError *error) {
            NSLog(@"Failed to update notification, error: %@", error.localizedDescription);
        }];
}

- (BOOL)handleAction:(GetSocialAction *)action
{
    if ([action.type isEqualToString:GetSocialActionOpenProfile])
    {
        self.userIdToShow = action.data[GetSocialActionDataKey_OpenProfile_UserId];
        if (GetSocial.isInitialized)
        {
            [self showNewFriend];
        }
        return YES;
    }
    if ([action.type isEqualToString:GetSocialActionCustom])
    {
        GSLogInfo(NO, NO, @"Received custom notification: %@", action.data);
        return YES;
    }
    return NO;
}

- (void)handleAction:(NSString *)action withPost:(GetSocialActivityPost *)post
{
    GSLogInfo(NO, NO, @"Activity Feed button clicked, actionType: %@", action);
    [PushNotificationView showNotificationWithTitle:@"Action Clicked" andMessage:action];
}

- (ActivityButtonActionHandler)defaultActionButtonHandler
{
    return ^void(NSString *action, GetSocialActivityPost *post) {
        [self handleAction:action withPost:post];
    };
}

- (GetSocialActionHandler)defaultActionHandler
{
    return ^BOOL(GetSocialAction *action) {
        return [self handleAction:action];
    };
}

- (void)registerInviteChannelPlugins
{
    // Register FB Messenger Invite Plugin
    GetSocialFBMessengerInvitePlugin *fbMessengerPlugin = [[GetSocialFBMessengerInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:fbMessengerPlugin forChannelId:GetSocial_InviteChannelPluginId_Facebook_Messenger];

    // Register KakaoTalk Invite Plugin
    GetSocialKakaoTalkInvitePlugin *kakaoTalkPlugin = [[GetSocialKakaoTalkInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:kakaoTalkPlugin forChannelId:GetSocial_InviteChannelPluginId_Kakao];

#if DISABLE_TWITTER != 1
    // Register Twitter Invite Plugin
    GetSocialTwitterInvitePlugin *twitterPlugin = [[GetSocialTwitterInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:twitterPlugin forChannelId:GetSocial_InviteChannelPluginId_Twitter];
#endif
    // Register Facebook Share Plugin
    GetSocialFacebookSharePlugin *fbSharePlugin = [[GetSocialFacebookSharePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:fbSharePlugin forChannelId:GetSocial_InviteChannelPluginId_Facebook];

    // Register VK Invite Plugin
    GetSocialVKInvitePlugin *vkInvitePlugin = [[GetSocialVKInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:vkInvitePlugin forChannelId:GetSocial_InviteChannelPluginId_VK];

    // Register Instagram Stories Plugin
    GetSocialInstagramStoriesInviteChannel *igStoriesPlugin = [GetSocialInstagramStoriesInviteChannel new];
    [GetSocial registerInviteChannelPlugin:igStoriesPlugin forChannelId:GetSocial_InviteChannelPluginId_Instagram_Stories];
}

- (void)updateFriendsCount
{
    if (![GetSocial isInitialized])
    {
        return;
    }
    [GetSocialUser friendsCountWithSuccess:^(int result) {
        self.friendsMenu.detail = [NSString stringWithFormat:@"You have %d friends", result];
    }
        failure:^(NSError *error) {
            GSLogError(NO, NO, @"Error updating friends count: %@", error.localizedDescription);
        }];

    NSArray<NSString *> *statuses = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_statuses"];
    NSArray<NSString *> *types = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_types"];
    NSArray<NSString *> *actions = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_actions"];

    GetSocialNotificationsCountQuery *query =
        statuses ? [GetSocialNotificationsCountQuery withStatuses:statuses] : [GetSocialNotificationsCountQuery withAllStatuses];

    if (types) [query setTypes:types];
    if (actions) [query setActions:actions];

    [GetSocialUser notificationsCountWithQuery:query
        success:^(int result) {
            self.notificationsMenu.detail = [NSString stringWithFormat:@"You have %d notifications", result];
        }
        failure:^(NSError *error) {
            GSLogError(NO, NO, @"Error updating notifications count: %@", error.localizedDescription);
        }];

    [GetSocialUser isPushNotificationsEnabledWithSuccess:^(BOOL result) {
        self.pushNotificationsEnabledMenu.isChecked = result;
    }
        failure:^(NSError *error) {
            NSLog(@"Failed to check PN status, %@", error.localizedDescription);
        }];
}

- (void)awakeFromNib
{
    [self loadMenu];
    [super awakeFromNib];
}

- (void)updateVersionInfo
{
    self.versionLabel.text = [NSString stringWithFormat:@"GetSocial iOS Demo\nSDK v%@. Build v%@.", [GetSocial sdkVersion],
                                                        [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];
}

- (void)loadMenu
{
    if (!self.menu)
    {
        self.menu = [NSMutableArray array];

        // User Management Menu
        self.userAuthenticationMenu = [MenuItem parentMenuItemWithTitle:@"User Management"];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Change Display Name"
                                                                               action:^{
                                                                                   [self changeDisplayName];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Change User Avatar"
                                                                               action:^{
                                                                                   [self changeUserAvatar];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Choose Avatar"
                                                                               action:^{
                                                                                   [self chooseUserAvatar];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Set User Property"
                                                                               action:^{
                                                                                   [self setProperty];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get User Property"
                                                                               action:^{
                                                                                   [self getProperty];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Add Facebook user identity"
                                                                               action:^{
                                                                                   [self addFBUserIdentityWithSuccess:nil failure:nil];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Add Custom user identity"
                                                                               action:^{
                                                                                   [self addCustomUserIdentityWithSuccess:nil failure:nil];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Remove Facebook user identity"
                                                                               action:^{
                                                                                   [self removeFBUserIdentity];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Remove Custom user identity"
                                                                               action:^{
                                                                                   [self removeCustomUserIdentity];
                                                                               }]];

        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Logout"
                                                                               action:^{
                                                                                   [self logOut];
                                                                               }]];

        [self.menu addObject:self.userAuthenticationMenu];

        // Friends Menu
        [self.menu addObject:self.friendsMenu = [MenuItem actionableMenuItemWithTitle:@"Friends"
                                                                               action:^{
                                                                                   [self openFriends];
                                                                               }]];

        self.friendsMenu.detail = @"You have 0 friends";

        // Smart Invites Menu
        self.smartInvitesMenu = [MenuItem parentMenuItemWithTitle:@"Smart Invites"];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open Smart Invites UI"
                                                                         action:^{
                                                                             [self openSmartInvites];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Send Customized Smart Invite"
                                                                         action:^{
                                                                             [self openCustomizedSmartInvite];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Create Invite Url"
                                                                         action:^{
                                                                             [self createInviteLink];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Check Referral Data"
                                                                         action:^{
                                                                             [self checkReferralData];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Check Referred Users(OLD)"
                                                                         action:^{
                                                                             [self checkReferredUsersOld];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Check Referred Users"
                                                                         action:^{
                                                                             [self checkReferredUsers];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Check Referrer Users"
                                                                         action:^{
                                                                             [self checkReferrerUsers];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Invite without UI"
                                                                         action:^{
                                                                             [self inviteWithoutUI];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Set Referrer"
                                                                         action:^{
                                                                             [self showSetReferrer];
                                                                         }]];

        [self.menu addObject:self.smartInvitesMenu];

        // AF menu
        self.activitiesMenu = [MenuItem parentMenuItemWithTitle:@"Activity Feed"];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Global Activity Feed"
                                                                       action:^{
                                                                           [[GetSocialUI createGlobalActivityFeedView] show];
                                                                       }]];
        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Global Activity Feed With Custom Handlers"
                                                      action:^{
                                                          GetSocialUIActivityFeedView *activityFeedView = [GetSocialUI createGlobalActivityFeedView];
                                                          [activityFeedView setActionButtonHandler:[self defaultActionButtonHandler]];
                                                          [activityFeedView setActionHandler:[self defaultActionHandler]];
                                                          [activityFeedView setHandlerForViewOpen:^() {
                                                              NSLog(@"Global feed is opened");
                                                          }
                                                              close:^() {
                                                                  NSLog(@"Global feed is closed");
                                                              }];
                                                          [activityFeedView setAvatarClickHandler:^(GetSocialPublicUser *user) {
                                                              [self didClickOnUser:user];
                                                          }];
                                                          [activityFeedView setMentionClickHandler:^(GetSocialId mention) {
                                                              if ([mention isEqualToString:GetSocialUI_Shortcut_App])
                                                              {
                                                                  [self showAlertWithText:@"Application mention clicked."];
                                                                  return;
                                                              }
                                                              [GetSocial userWithId:mention
                                                                  success:^(GetSocialPublicUser *publicUser) {
                                                                      [self didClickOnUser:publicUser];
                                                                  }
                                                                  failure:^(NSError *error) {
                                                                      NSLog(@"Failed to get user, error: %@", error.localizedDescription);
                                                                  }];
                                                          }];
                                                          [activityFeedView setTagClickHandler:^(NSString *tagName) {
                                                              GetSocialUIActivityFeedView *tagFeedView = [GetSocialUI createGlobalActivityFeedView];
                                                              [tagFeedView setWindowTitle:[NSString stringWithFormat:@"Search #%@", tagName]];
                                                              [tagFeedView setFilterByTags:@[ tagName ]];
                                                              [tagFeedView setReadOnly:YES];
                                                              [tagFeedView show];
                                                          }];
                                                          [activityFeedView setUiActionHandler:^(GetSocialUIActionType actionType,
                                                                                                 GetSocialUIPendingAction pendingAction) {
                                                              switch (actionType)
                                                              {
                                                                  case GetSocialUIActionLikeActivity:
                                                                  case GetSocialUIActionLikeComment:
                                                                  case GetSocialUIActionPostActivity:
                                                                  case GetSocialUIActionPostComment:
                                                                      if ([GetSocialUser isAnonymous])
                                                                      {
                                                                          [self showAlertToChooseAuthorizationOptionToPerform:pendingAction];
                                                                          break;
                                                                      }
                                                                  default:
                                                                      pendingAction();
                                                              }
                                                          }];
                                                          [activityFeedView show];
                                                      }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Custom Activity Feed (DemoFeed)"
                                                                       action:^{
                                                                           GetSocialUIActivityFeedView *activityFeedView =
                                                                               [GetSocialUI createActivityFeedView:@"DemoFeed"];
                                                                           [activityFeedView
                                                                               setActionButtonHandler:[self defaultActionButtonHandler]];
                                                                           [activityFeedView setActionHandler:[self defaultActionHandler]];
                                                                           [activityFeedView show];
                                                                       }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"My Global Activity Feed"
                                                                       action:^{
                                                                           [self showGlobalFeedForUser:[GetSocialUser userId]
                                                                                             withTitle:@"My Global Activity Feed"];
                                                                       }]];

        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Friends Global Activity Feed"
                                                      action:^{
                                                          GetSocialUIActivityFeedView *activityFeedView = [GetSocialUI createGlobalActivityFeedView];
                                                          [activityFeedView setActionButtonHandler:[self defaultActionButtonHandler]];
                                                          [activityFeedView setActionHandler:[self defaultActionHandler]];
                                                          [activityFeedView setShowFriendsFeed:YES];
                                                          [activityFeedView show];
                                                      }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"My Custom Activity Feed"
                                                                       action:^{
                                                                           GetSocialUIActivityFeedView *activityFeedView =
                                                                               [GetSocialUI createActivityFeedView:@"DemoFeed"];
                                                                           [activityFeedView
                                                                               setActionButtonHandler:[self defaultActionButtonHandler]];
                                                                           [activityFeedView setActionHandler:[self defaultActionHandler]];
                                                                           [activityFeedView setWindowTitle:@"My Custom Activity Feed"];
                                                                           [activityFeedView setReadOnly:NO];
                                                                           [activityFeedView setFilterByUser:[GetSocialUser userId]];
                                                                           [activityFeedView show];
                                                                       }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Activity Details"
                                                                       action:^{
                                                                           [self showChooseActivityAlert:YES];
                                                                       }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Activity Details(without activity feed)"
                                                                       action:^{
                                                                           [self showChooseActivityAlert:NO];
                                                                       }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Activity"
                                                                       action:^{
                                                                           [self openPostActivityView];
                                                                       }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Chat feed (Only for testing)"
                                                                       action:^{
                                                                           NSString *chatId = @"chat_test";
                                                                           GetSocialUIActivityFeedView *view =
                                                                               [GetSocialUI createActivityFeedView:chatId];
                                                                           [view show];
                                                                       }]];

        [self.menu addObject:self.activitiesMenu];

        // Notifications Menu
        [self.menu addObject:self.notificationsMenu = [MenuItem parentMenuItemWithTitle:@"Notifications"]];
        [self.notificationsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Notifications List"
                                                                          action:^{
                                                                              [self openNotifications];
                                                                          }]];
        [self.notificationsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Send Notification"
                                                                          action:^{
                                                                              [self sendNotification];
                                                                          }]];

        [self.notificationsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Notification Center UI"
                                                                          action:^{
                                                                              [self showNotificationCenterUI];
                                                                          }]];

        // Promo Codes
        ParentMenuItem *promoCodes = [MenuItem parentMenuItemWithTitle:@"Promo Codes"];
        [promoCodes addSubmenu:[MenuItem actionableMenuItemWithTitle:@"My Promo Code"
                                                              action:^{
                                                                  [self showMyPromoCode];
                                                              }]];
        [promoCodes addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Create Promo Code"
                                                              action:^{
                                                                  [self createPromoCode];
                                                              }]];
        [promoCodes addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Claim Promo Code"
                                                              action:^{
                                                                  [self claimPromoCode];
                                                              }]];
        [promoCodes addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Promo Code Info"
                                                              action:^{
                                                                  [self getPromoCodeInfo];
                                                              }]];
        [self.menu addObject:promoCodes];

        // Send local notification Menu
        [self.menu addObject:[MenuItem actionableMenuItemWithTitle:@"Send local PN"
                                                            action:^{
                                                                [self sendLocalNotification];
                                                            }]];

        self.notificationsMenu.detail = @"You have 0 notifications";

        // UI Customization Menu
        self.uiCustomizationMenu = [MenuItem parentMenuItemWithTitle:@"UI Customization"];
        self.uiCustomizationMenu.detail = @"Current UI: Default";

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Default UI"
                                                                               isChecked:YES
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadDefaultUI];
                                                                                  }]];

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Default UI Landscape"
                                                                               isChecked:NO
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadDefaultUILandscape];
                                                                                  }]];

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Light UI - Portrait"
                                                                               isChecked:NO
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadLightUIPortrait];
                                                                                  }]];

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Light UI - Landscape"
                                                                               isChecked:NO
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadLightUILandscape];
                                                                                  }]];

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Dark UI - Portrait"
                                                                               isChecked:NO
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadDarkUIPortrait];
                                                                                  }]];

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Dark UI - Landscape"
                                                                               isChecked:NO
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadDarkUILandscape];
                                                                                  }]];

        [self.menu addObject:self.uiCustomizationMenu];

        // Settings Menu
        self.settingsMenu = [MenuItem parentMenuItemWithTitle:@"Settings"];

        self.languageMenu = [MenuItem parentMenuItemWithTitle:@"Change Language"];
        NSString *currentLanguage = [GetSocial language];
        if (currentLanguage != nil)
        {
            [self changeLanguage:currentLanguage];
        }

        NSDictionary *availableLanguages = [GetSocialConstants allLanguageCodes];

        NSArray *sortedLanguages = [[availableLanguages allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [availableLanguages[obj1] localizedCaseInsensitiveCompare:availableLanguages[obj2]];
        }];

        for (NSString *key in sortedLanguages)
        {
            MenuItem *menuItem = [MenuItem groupedCheckableMenuItemWithTitle:availableLanguages[key]
                                                                   isChecked:[[GetSocial language] isEqualToString:key]
                                                                      action:^BOOL(BOOL isChecked) {
                                                                          return [self changeLanguage:key];
                                                                      }];
            [menuItem setDetail:[NSString stringWithFormat:@"Language code: %@", key]];
            [self.languageMenu addSubmenu:menuItem];
        }

        __weak typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UserWasUpdatedNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note) {
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              NSString *currentLanguage = [GetSocial language];
                                                              if (currentLanguage != nil)
                                                              {
                                                                  [self changeLanguage:currentLanguage];

                                                                  for (CheckableMenuItem *menuItem in weakSelf.languageMenu.subitems)
                                                                  {
                                                                      if ([menuItem.detail hasSuffix:currentLanguage])
                                                                      {
                                                                          [menuItem setIsChecked:YES];
                                                                      }
                                                                  }
                                                              }
                                                          });
                                                      }];

        [self.settingsMenu addSubmenu:self.languageMenu];
        self.pushNotificationsEnabledMenu =
            [MenuItem checkableMenuItemWithTitle:@"Enable Push Notifications"
                                       isChecked:YES
                                          action:^BOOL(BOOL isChecked) {
                                              [GetSocialUser setPushNotificationsEnabled:isChecked
                                                  success:^{
                                                      self.pushNotificationsEnabledMenu.isChecked = isChecked;
                                                  }
                                                  failure:^(NSError *error) {
                                                      NSLog(@"Failed to change PN status, %@", error.localizedDescription);
                                                  }];
                                              return NO;
                                          }];
        [self.settingsMenu addSubmenu:self.pushNotificationsEnabledMenu];

        self.statusBarMenuItem = [MenuItem checkableMenuItemWithTitle:@"Status bar hidden"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   self.statusBarHidden = isChecked;
                                                                   [self setNeedsStatusBarAppearanceUpdate];
                                                                   return YES;
                                                               }];
        [self.settingsMenu addSubmenu:self.statusBarMenuItem];

        [self.menu addObject:self.settingsMenu];

        [self.menu addObject:[MenuItem actionableMenuItemWithTitle:@"In-app purchase"
                                                            action:^{
                                                                IAPViewController *vc =
                                                                    [UIStoryboard viewControllerForName:@"iapviewcontroller"
                                                                                           inStoryboard:GetSocialStoryboardInAppPurchase];
                                                                [self.mainNavigationController pushViewController:vc animated:YES];
                                                            }]];
        ParentMenuItem *customAnalyticsEventsMenu = [MenuItem parentMenuItemWithTitle:@"Custom Analytics Events"];
        [self.menu addObject:customAnalyticsEventsMenu];
        [customAnalyticsEventsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Level Completed"
                                                                             action:^{
                                                                                 [self trackCustomEventWithName:@"level_completed"
                                                                                                     properties:@{@"level" : @"1"}];
                                                                             }]];
        [customAnalyticsEventsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Tutorial Completed"
                                                                             action:^{
                                                                                 [self trackCustomEventWithName:@"tutorial_completed" properties:nil];
                                                                             }]];
        [customAnalyticsEventsMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Achievement Unlocked"
                                                      action:^{
                                                          [self trackCustomEventWithName:@"achievement_unlocked"
                                                                              properties:@{@"achievement" : @"early_backer", @"item" : @"car001"}];
                                                      }]];
    }
}

- (void)didClickOnUser:(GetSocialPublicUser *)user
{
    if ([user.userId isEqualToString:[GetSocialUser userId]])
    {
        [self showActionDialogForCurrentUser:user];
        return;
    }
    [GetSocialUser isFriend:user.userId
        success:^(BOOL isFriend) {
            if (isFriend)
            {
                [self showActionDialogForFriend:user];
            }
            else
            {
                [self showActionDialogForNonFriend:user];
            }
        }
        failure:^(NSError *error) {
            NSLog(@"Failed to check if friends, error: %@", error.localizedDescription);
        }];
}

- (void)showGlobalFeedForUser:(GetSocialId)userId withTitle:(NSString *)title
{
    GetSocialUIActivityFeedView *activityFeedView = [GetSocialUI createGlobalActivityFeedView];
    [activityFeedView setActionButtonHandler:[self defaultActionButtonHandler]];
    [activityFeedView setActionHandler:[self defaultActionHandler]];
    [activityFeedView setWindowTitle:title];
    [activityFeedView setReadOnly:YES];
    [activityFeedView setFilterByUser:userId];
    [activityFeedView show];
}

- (void)showActionDialogForCurrentUser:(GetSocialPublicUser *)user
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:@"Choose action"
                                                   message:[NSString stringWithFormat:@"Choose one of possible actions"]
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@[ @"Show User Feed" ]];
    [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            [self showGlobalFeedForUser:user.userId withTitle:@"My Global Feed"];
        }
    }];
}

- (void)showActionDialogForFriend:(GetSocialPublicUser *)user
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:[NSString stringWithFormat:@"User %@", user.displayName]
                                                   message:[NSString stringWithFormat:@"Choose one of possible actions"]
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@[ @"Show User Feed", @"Remove from Friends" ]];

    [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            switch (selectedIndex)
            {
                case 0:
                    [self showGlobalFeedForUser:user.userId withTitle:[NSString stringWithFormat:@"%@ Global Feed", user.displayName]];
                    break;

                case 1:
                    [GetSocialUser removeFriend:user.userId
                        success:^(int friendsCount) {
                            [self showAlertWithText:[NSString stringWithFormat:@"%@ removed from friends.", user.displayName]];
                        }
                        failure:^(NSError *error) {
                            NSLog(@"Failed to remove friend, error: %@", error.localizedDescription);
                        }];
                    break;
            }
        }
    }];
}

- (void)showActionDialogForNonFriend:(GetSocialPublicUser *)user
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:[NSString stringWithFormat:@"User %@", user.displayName]
                                                   message:[NSString stringWithFormat:@"Choose one of possible actions"]
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@[ @"Show User Feed", @"Add to Friends" ]];

    [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            switch (selectedIndex)
            {
                case 0:
                    [self showGlobalFeedForUser:user.userId withTitle:[NSString stringWithFormat:@"%@ Global Feed", user.displayName]];
                    break;

                case 1:
                    [GetSocialUser addFriend:user.userId
                        success:^(int friendsCount) {
                            [self showAlertWithText:[NSString stringWithFormat:@"%@ added to friends.", user.displayName]];
                        }
                        failure:^(NSError *error) {
                            NSLog(@"Failed to add friend, error: %@", error.localizedDescription);
                        }];
                    break;
            }
        }
    }];
}

- (void)showChooseActivityAlert:(BOOL)showFeed
{
    GetSocialActivitiesQuery *query = [GetSocialActivitiesQuery postsForGlobalFeed];
    [query setLimit:5];
    [GetSocial activitiesWithQuery:query
        success:^(NSArray<GetSocialActivityPost *> *_Nonnull result) {
            NSMutableArray *activityIds = [@[] mutableCopy];
            NSMutableArray *activityContents = [@[] mutableCopy];
            for (GetSocialActivityPost *activity in result)
            {
                NSString *content = activity.text ?: activity.imageUrl ?: activity.buttonTitle;
                [activityIds addObject:activity.activityId];
                [activityContents addObject:content];
            }
            UISimpleAlertViewController *alertViewController =
                [[UISimpleAlertViewController alloc] initWithTitle:@"Activity ID"
                                                           message:@"Select an activity ID to be displayed"
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:activityContents];
            [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
                if (!didCancel)
                {
                    GetSocialUIActivityDetailsView *detailsView = [GetSocialUI createActivityDetailsView:activityIds[selectedIndex]];
                    [detailsView setActionButtonHandler:[self defaultActionButtonHandler]];
                    [detailsView setActionHandler:[self defaultActionHandler]];
                    [detailsView setUiActionHandler:^(GetSocialUIActionType actionType, GetSocialUIPendingAction pendingAction) {
                        NSLog(@"Action performed %ld", (long)actionType);
                        pendingAction();
                    }];
                    [detailsView setWindowTitle:@"Activity Details"];
                    [detailsView setShowActivityFeedView:showFeed];
                    [detailsView setHandlerForViewOpen:^{
                        NSLog(@"On view opened");
                    }
                        close:^{
                            NSLog(@"On view closed");
                        }];
                    [detailsView show];
                }
            }];
        }
        failure:^(NSError *_Nonnull error) {
            NSLog(@"Error loading activities %@", error);
        }];
}

- (void)showAlertToChooseAuthorizationOptionToPerform:(GetSocialUIPendingAction)pendingUiAction
{
    UISimpleAlertViewController *authorizationChooser = [[UISimpleAlertViewController alloc] initWithTitle:@"Authorize to perform an action"
                                                                                                   message:@"Choose authorization option"
                                                                                         cancelButtonTitle:@"Cancel"
                                                                                         otherButtonTitles:@[ @"Facebook", @"Custom" ]];
    [authorizationChooser showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (didCancel)
        {
            GSLogInfo(YES, NO, @"Can not perform action for anonymous user");
        }
        else
        {
            if (selectedIndex == 0)
            {
                [GetSocialUI closeView:YES];
                [self addFBUserIdentityWithSuccess:^{
                    [GetSocialUI restoreView];
                    pendingUiAction();
                }
                    failure:^{
                        [GetSocialUI restoreView];
                        GSLogInfo(YES, NO, @"Can not perform action because of authorization error");
                    }];
            }
            else if (selectedIndex == 1)
            {
                [self addCustomUserIdentityWithSuccess:pendingUiAction
                                               failure:^{
                                                   GSLogInfo(YES, NO, @"Can not perform action because of authorization error");
                                               }];
            }
        }
    }];
}

#pragma mark - Authentication

- (FBSDKLoginManager *)facebookSdkManager
{
    if (!_facebookSdkManager)
    {
        _facebookSdkManager = [FBSDKLoginManager new];
        _facebookSdkManager.loginBehavior = FBSDKLoginBehaviorBrowser;
    }
    return _facebookSdkManager;
}

- (void)loginWithFacebookWithHandler:(FBSDKLoginManagerLoginResultBlock)handler
{
    [self.facebookSdkManager logInWithPermissions:@[ @"email", @"user_friends", @"public_profile" ]
                               fromViewController:[UIApplication sharedApplication].keyWindow.rootViewController
                                          handler:handler];
}

- (void)changeUserAvatar
{
    [self showActivityIndicatorView];
    [GetSocialUser setAvatarUrl:[UserIdentityUtils randomAvatarUrl]
        success:^{
            [self hideActivityIndicatorView];
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            GSLogInfo(YES, NO, @"User avatar has been successfully updated");
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            GSLogError(YES, NO, @"Error changing user avatar: %@", error.localizedDescription);
        }];
}

- (void)chooseUserAvatar
{
    self.avatarImagePicker = [[UIImagePickerController alloc] init];
    self.avatarImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.avatarImagePicker.delegate = self;

    [self presentViewController:self.avatarImagePicker animated:YES completion:nil];
}

- (void)setProperty
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Set User Property"
                                                                                    message:@"Enter key and value"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:@[ @"Ok" ]];

    [alert addTextFieldWithPlaceholder:@"Key" defaultText:nil isSecure:NO];
    [alert addTextFieldWithPlaceholder:@"Value" defaultText:nil isSecure:NO];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            [self showActivityIndicatorView];
            NSString *key = [alert contentOfTextFieldAtIndex:0];
            NSString *value = [alert contentOfTextFieldAtIndex:1];
            [GetSocialUser setPublicPropertyValue:value
                forKey:key
                success:^{
                    [self hideActivityIndicatorView];
                    [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
                    GSLogInfo(YES, NO, @"User property was successfully set");
                }
                failure:^(NSError *error) {
                    [self hideActivityIndicatorView];
                    GSLogError(YES, NO, @"Error changing user property: %@", error.localizedDescription);
                }];
        }
    }];
}

- (void)getProperty
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Get User Property"
                                                                                    message:@"Enter key"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:@[ @"Ok" ]];

    [alert addTextFieldWithPlaceholder:nil defaultText:nil isSecure:NO];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            NSString *key = [alert contentOfTextFieldAtIndex:0];

            NSString *value = [GetSocialUser publicPropertyValueForKey:key];
            [self showAlertWithText:[NSString stringWithFormat:@"%@ = %@", key, value]];
        }
    }];
}

- (void)changeDisplayName
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Change Display Name"
                                                                                    message:@"Enter new display name"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:@[ @"Ok" ]];

    [alert addTextFieldWithPlaceholder:nil defaultText:[UserIdentityUtils randomDisplayName] isSecure:NO];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            [self showActivityIndicatorView];
            NSString *newDisplayName = [alert contentOfTextFieldAtIndex:0];
            [GetSocialUser setDisplayName:newDisplayName
                success:^{
                    [self hideActivityIndicatorView];
                    [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
                    GSLogInfo(YES, NO, @"User display name has been successfully updated");
                }
                failure:^(NSError *error) {
                    [self hideActivityIndicatorView];
                    GSLogError(YES, NO, @"Error changing user display name: %@", error.localizedDescription);
                }];
        }
    }];
}

- (void)addFBUserIdentityWithSuccess:(void (^)(void))success failure:(void (^)(void))failure
{
    NSDictionary *authIdentities = [GetSocialUser authIdentities];
    if (!authIdentities[GetSocial_AuthIdentityProviderId_Facebook])
    {
        [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
        [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *loginError) {
            if (!loginError && !result.isCancelled)
            {
                [self addIdentity:[GetSocialAuthIdentity facebookIdentityWithAccessToken:result.token.tokenString]
                          success:^{
                              [self setFacebookDisplayName];
                              [self setFacebookAvatar];
                              ExecuteBlock(success);
                          }
                          failure:failure];
            }
        }];
    }
    else
    {
        GSLogInfo(YES, NO, @"User has already a Facebook identity.");
    }
}

- (void)setFacebookAvatar
{
    FBSDKProfile *profile = [FBSDKProfile currentProfile];
    NSURL *profileImageUrl = [profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:CGSizeMake(250, 250)];

    GSLogInfo(NO, NO, @"FB Avatar url: %@", profileImageUrl);

    [GetSocialUser setAvatarUrl:profileImageUrl.absoluteString
        success:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Error changing user display name to facebook provided: %@", error.localizedDescription);
        }];
}

- (void)setFacebookDisplayName
{
    FBSDKProfile *profile = [FBSDKProfile currentProfile];
    NSString *displayName = [NSString stringWithFormat:@"%@ %@", profile.firstName, profile.lastName];

    GSLogInfo(NO, NO, @"FB Display name: %@", displayName);

    [GetSocialUser setDisplayName:displayName
        success:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Error changing user display name to facebook provided: %@", error.localizedDescription);
        }];
}

- (void)removeFBUserIdentity
{
    [self.facebookSdkManager logOut];
    if ([GetSocialUser authIdentities][GetSocial_AuthIdentityProviderId_Facebook])
    {
        [self showActivityIndicatorView];
        [GetSocialUser removeAuthIdentityWithProviderId:GetSocial_AuthIdentityProviderId_Facebook
            success:^{
                [self hideActivityIndicatorView];
                GSLogInfo(YES, NO, @"Identity removed for Provider %@.", GetSocial_AuthIdentityProviderId_Facebook);
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            }
            failure:^(NSError *error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Failed to remove Identity for Provider %@, error: %@", GetSocial_AuthIdentityProviderId_Facebook,
                           [error localizedDescription]);
            }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User doesn't have UserIdentity for Provider %@.", GetSocial_AuthIdentityProviderId_Facebook);
    }
}

- (void)addCustomUserIdentityWithSuccess:(void (^)(void))success failure:(void (^)(void))failure
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Add Custom User identity"
                                                                                    message:@"Enter UserId and Token"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:@[ @"Ok" ]];

    [alert addTextFieldWithPlaceholder:@"UserId" defaultText:nil isSecure:NO];
    [alert addTextFieldWithPlaceholder:@"Token" defaultText:nil isSecure:YES];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            NSString *providerId = kCustomProvider;
            NSString *providerUserId = [alert contentOfTextFieldAtIndex:0];
            NSString *accessToken = [alert contentOfTextFieldAtIndex:1];

            GetSocialAuthIdentity *identity =
                [GetSocialAuthIdentity customIdentityForProvider:providerId userId:providerUserId accessToken:accessToken];

            [self addIdentity:identity success:success failure:failure];
        }
    }];
}

- (void)removeCustomUserIdentity
{
    if ([GetSocialUser authIdentities][kCustomProvider])
    {
        [self showActivityIndicatorView];
        [GetSocialUser removeAuthIdentityWithProviderId:kCustomProvider
            success:^{
                [self hideActivityIndicatorView];
                GSLogInfo(YES, NO, @"User identity removed for Provider '%@'", kCustomProvider);
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            }
            failure:^(NSError *error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Failed to remove user identity for Provider '%@', error: %@", kCustomProvider, [error localizedDescription]);
            }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User doesn't have user identity for Provider '%@'", kCustomProvider);
    }
}

- (void)logOut
{
    [self showActivityIndicatorView];
    [GetSocialUser resetWithSuccess:^() {
        [self hideActivityIndicatorView];
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];

        GSLogInfo(YES, NO, @"User was successfully logged out.");
    }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            GSLogError(YES, NO, @"Failed to log out user, error: %@", [error localizedDescription]);
        }];
}

- (void)addIdentity:(GetSocialAuthIdentity *)identity success:(void (^)(void))success failure:(void (^)(void))failure
{
    [self showActivityIndicatorView];
    [GetSocialUser addAuthIdentity:identity
        success:^{
            [self hideActivityIndicatorView];
            GSLogInfo(YES, NO, @"User identity %@ added, result: Identity added", identity);
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            ExecuteBlock(success);
        }
        conflict:^(GetSocialConflictUser *conflictUser) {
            [self hideActivityIndicatorView];
            [self showAlertViewToResolveIdentityConflictWithConflictUser:conflictUser
                                                      conflictResolution:^(BOOL switchUser) {
                                                          if (switchUser)
                                                          {
                                                              [self callSwitchUserWithIdentity:identity success:success failure:failure];
                                                          }
                                                      }];
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            GSLogError(YES, NO, @"Failed to add user identity %@, error: %@", identity, [error localizedDescription]);
            ExecuteBlock(failure);
        }];
}

- (void)callSwitchUserWithIdentity:(GetSocialAuthIdentity *)identity success:(void (^)(void))success failure:(void (^)(void))failure
{
    [self showActivityIndicatorView];
    [GetSocialUser switchUserToIdentity:identity
        success:^{
            [self hideActivityIndicatorView];
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            GSLogInfo(YES, NO, @"User switching was successfull.");
            ExecuteBlock(success);
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            GSLogInfo(YES, NO, @"User switching failed, error: %@", [error description]);
            ExecuteBlock(failure);
        }];
}

- (void)showAlertViewToResolveIdentityConflictWithConflictUser:(GetSocialConflictUser *)conflictUser
                                            conflictResolution:(void (^)(BOOL switchUser))conflictResolution
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc]
            initWithTitle:@"Conflict"
                  message:@"The new identity is already linked to another user. Which one do you want to continue using?"
        cancelButtonTitle:[NSString stringWithFormat:@"%@ (Remote)", [conflictUser userId]]
        otherButtonTitles:@[ [NSString stringWithFormat:@"%@ (Current)", [GetSocialUser userId]] ]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            BOOL switchUser = didCancel;
            if (conflictResolution)
            {
                conflictResolution(switchUser);
            }
        }];
    });
}

#pragma mark - Friends

- (void)openFriends
{
    FriendsViewController *vc = [UIStoryboard viewControllerForName:@"Friends" inStoryboard:GetSocialStoryboardSocialGraph];

    [self.mainNavigationController pushViewController:vc animated:YES];
}

- (void)showNewFriend
{
    [GetSocial userWithId:self.userIdToShow
        success:^(GetSocialPublicUser *_Nonnull publicUser) {
            NewFriendViewController *newFriendViewController =
                [UIStoryboard viewControllerForName:@"NewFriendViewController" inStoryboard:GetSocialStoryboardSocialGraph];
            [newFriendViewController setPublicUser:publicUser];
            [UISimpleAlertViewController hideAlertView];
            if ([UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController != nil)
            {
                [[UIApplication sharedApplication].keyWindow.rootViewController
                    dismissViewControllerAnimated:YES
                                       completion:^{
                                           [[UIApplication sharedApplication].keyWindow.rootViewController
                                               presentViewController:newFriendViewController
                                                            animated:YES
                                                          completion:nil];
                                       }];
            }
            else
            {
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:newFriendViewController
                                                                                             animated:YES
                                                                                           completion:nil];
            }
            self.userIdToShow = nil;
        }
        failure:^(NSError *_Nonnull error) {
            GSLogError(YES, NO, @"Fetch user failed, error: %@", [error description]);
        }];
}

#pragma mark - Smart Invites

- (void)openSmartInvites
{
    [[GetSocialUI createInvitesView] show];
}

- (void)checkReferralData
{
    [self showActivityIndicatorView];
    [GetSocial referralDataWithSuccess:^(GetSocialReferralData *_Nullable referralData) {
        [self hideActivityIndicatorView];
        if (referralData == nil)
        {
            GSLogInfo(YES, NO, @"No referral data");
        }
        else
        {
            NSMutableString *linkParams = [NSMutableString new];
            [referralData.referralLinkParams enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop)
            {
                [linkParams appendFormat:@"%@ = %@, ", key, obj];
            }];
            NSString *promoCode = referralData.referralLinkParams[GetSocial_PromoCode];
            if (promoCode != nil)
            {
                [linkParams appendFormat:@"\n\n PROMO CODE:\n %@", promoCode];
            }

            NSString *message = [NSString stringWithFormat: @"Referral data received: token: %@, referrerUserId: %@, referrerChannelId: %@, isFirstMatch: %i, isGuaranteedMatch: %i, linkParams: %@.",
                    [referralData token], [referralData referrerUserId], [referralData referrerChannelId], [referralData isFirstMatch],
                    [referralData isGuaranteedMatch], linkParams];
            [[ConsoleViewController sharedController] log:LogLevelInfo message:message context:@"checkReferralData: line 1379"];
            UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Referral Data"
                                                                                            message:message
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:promoCode == nil ? @[] : @[ @"Claim"
                                                                                  ]];
            [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
                if (!didCancel)
                {
                    [GetSocial claimPromoCode:promoCode
                        success:^(GetSocialPromoCode *_Nonnull promoCode) {
                            [self hideActivityIndicatorView];
                            [self showAlertWithTitle:@"Claimed Promo Code" andText:[MainViewController formatPromoCode:promoCode]];
                        }
                        failure:^(NSError *_Nonnull error) {
                            [self hideActivityIndicatorView];
                            GSLogError(YES, NO, @"Error claiming promo code: %@", error.localizedDescription);
                        }];
                }
            }];
        }
    }
        failure:^(NSError *_Nonnull error) {
            [self hideActivityIndicatorView];
            GSLogInfo(YES, NO, @"Could not get referral data: %@", [error description]);
        }];
}

- (void)checkReferredUsers
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Get Referrer Users"
                                                                                    message:@"Enter event name"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:@[ @"Ok" ]];

    [alert addTextFieldWithPlaceholder:nil defaultText:@"" isSecure:NO];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel) {
            [self showActivityIndicatorView];
            NSString *eventName = [alert contentOfTextFieldAtIndex:0];
            GetSocialReferralUsersQuery* query = nil;
            if (eventName.length == 0) {
                query = [GetSocialReferralUsersQuery allUsers];
            } else {
                query = [GetSocialReferralUsersQuery usersForEvent:eventName];
            }
            [GetSocial referredUsersWithQuery:query success:^(NSArray<GetSocialReferralUser *> *_Nonnull referredUsers) {
                        [self hideActivityIndicatorView];
                        __block NSString *messageContent = @"No referred users";
                        if (referredUsers.count > 0)
                        {
                            messageContent = @"";
                            [referredUsers enumerateObjectsUsingBlock:^(GetSocialReferralUser *_Nonnull referralUser, NSUInteger idx, BOOL *_Nonnull stop) {
                                NSDateFormatter *formatter = [NSDateFormatter new];
                                formatter.dateFormat = @"MM-dd-yyyy HH:mm";
                                NSString *referredUserInfo = [NSString
                                        stringWithFormat:@"%@(event=%@, date=%@, data=%@), ", referralUser.displayName, referralUser.event,
                                                         [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:referralUser.eventDate]], referralUser.eventData];

                                messageContent = [messageContent stringByAppendingString:referredUserInfo];
                            }];
                            messageContent = [messageContent substringToIndex:messageContent.length - 2];
                        }
                        GSLogInfo(YES, NO, @"%@", messageContent);
                    }
                                       failure:^(NSError *_Nonnull error) {
                                           [self hideActivityIndicatorView];
                                           GSLogInfo(YES, NO, @"Could not get list of referred users: %@", [error description]);
                                       }];
        }
    }];
}

- (void)checkReferredUsersOld
{
    [self showActivityIndicatorView];
    [GetSocial referredUsersWithSuccess:^(NSArray<GetSocialReferredUser *> *_Nonnull referredUsers) {
        [self hideActivityIndicatorView];
        __block NSString *messageContent = @"No referred users";
        if (referredUsers.count > 0)
        {
            messageContent = @"";
            [referredUsers enumerateObjectsUsingBlock:^(GetSocialReferredUser *_Nonnull referredUser, NSUInteger idx, BOOL *_Nonnull stop) {
                NSDateFormatter *formatter = [NSDateFormatter new];
                formatter.dateFormat = @"MM-dd-yyyy HH:mm";
                NSString *referredUserInfo = [NSString
                    stringWithFormat:@"%@(on %@ via %@, reinstall=%d, installSuspicious=%d, installPlatform=%@), ", referredUser.displayName,
                                     [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:referredUser.installationDate]],
                                     referredUser.installationChannel, referredUser.isReinstall, referredUser.isInstallSuspicious,
                                     referredUser.installationPlatform];
                messageContent = [messageContent stringByAppendingString:referredUserInfo];
            }];
            messageContent = [messageContent substringToIndex:messageContent.length - 2];
        }
        GSLogInfo(YES, NO, @"%@", messageContent);
    }
        failure:^(NSError *_Nonnull error) {
            [self hideActivityIndicatorView];
            GSLogInfo(YES, NO, @"Could not get list of referred users: %@", [error description]);
        }];
}

- (void)checkReferrerUsers
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Get Referrer Users"
                                                                                    message:@"Enter event name"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:@[ @"Ok" ]];

    [alert addTextFieldWithPlaceholder:nil defaultText:@"" isSecure:NO];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel) {
            [self showActivityIndicatorView];
            NSString *eventName = [alert contentOfTextFieldAtIndex:0];
            GetSocialReferralUsersQuery* query = nil;
            if (eventName.length == 0) {
                query = [GetSocialReferralUsersQuery allUsers];
            } else {
                query = [GetSocialReferralUsersQuery usersForEvent:eventName];
            }
            [GetSocial referrerUsersWithQuery:query success:^(NSArray<GetSocialReferralUser *> *_Nonnull referrerUsers) {
                        [self hideActivityIndicatorView];
                        __block NSString *messageContent = @"No referrer users";
                        if (referrerUsers.count > 0)
                        {
                            messageContent = @"";
                            [referrerUsers enumerateObjectsUsingBlock:^(GetSocialReferralUser *_Nonnull referralUser, NSUInteger idx, BOOL *_Nonnull stop) {
                                NSDateFormatter *formatter = [NSDateFormatter new];
                                formatter.dateFormat = @"MM-dd-yyyy HH:mm";
                                NSString *referredUserInfo = [NSString
                                        stringWithFormat:@"%@(event=%@, date=%@, data=%@), ", referralUser.displayName, referralUser.event,
                                                         [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:referralUser.eventDate]], referralUser.eventData];

                                messageContent = [messageContent stringByAppendingString:referredUserInfo];
                            }];
                            messageContent = [messageContent substringToIndex:messageContent.length - 2];
                        }
                        GSLogInfo(YES, NO, @"%@", messageContent);
                    }
                                       failure:^(NSError *_Nonnull error) {
                                           [self hideActivityIndicatorView];
                                           GSLogInfo(YES, NO, @"Could not get list of referrer users: %@", [error description]);
                                       }];
        }
    }];
}

- (void)inviteWithoutUI
{
    NSMutableArray *providerNames = [NSMutableArray array];
    NSArray<GetSocialInviteChannel *> *channels = [GetSocial inviteChannels];
    for (GetSocialInviteChannel *channel in channels)
    {
        if (channel.name)
        {
            [providerNames addObject:channel.name];
        }
    }

    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Smart Invite"
                                                                                    message:@"Choose provider"
                                                                          cancelButtonTitle:@"Cancel"
                                                                          otherButtonTitles:providerNames];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            NSString *selectedProviderId = [channels[selectedIndex] channelId];
            [self performSelector:@selector(callSendInviteWithProviderId:) withObject:selectedProviderId afterDelay:.5f];
        }
    }];
}

- (void)showSetReferrer {
    [self.mainNavigationController
        pushViewController:[UIStoryboard viewControllerForName:@"SetReferrer" inStoryboard:GetSocialStoryboardSmartInvites]
                  animated:YES];
}

- (void)createInviteLink
{
    [GetSocial createInviteLinkWithParams:nil
        success:^(NSString *_Nonnull result) {
            GSLogInfo(YES, NO, @"Created invite url: %@", result);
        }
        failure:^(NSError *_Nonnull error) {
            GSLogInfo(YES, NO, @"Failed to create invite url, error: %@", error);
        }];
}

- (void)callSendInviteWithProviderId:(NSString *)providerId
{
    [self showActivityIndicatorView];
    [GetSocial sendInviteWithChannelId:providerId
        success:^{
            [self hideActivityIndicatorView];
            GSLogInfo(NO, NO, @"Sending invites was successful");
        }
        cancel:^{
            [self hideActivityIndicatorView];
            GSLogInfo(NO, NO, @"Sending invites was cancelled");
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            GSLogInfo(NO, NO, @"Sending invites failed, error: %@", [error description]);
        }];
}

- (void)openCustomizedSmartInvite
{
    UIViewController *vc = [UIStoryboard viewControllerForName:@"CustomSmartInvite" inStoryboard:GetSocialStoryboardSmartInvites];
    [self.mainNavigationController pushViewController:vc animated:YES];
}

#pragma mark - Activities

- (void)openPostActivityView
{
    PostActivityViewController *vc = [UIStoryboard viewControllerForName:@"PostActivity" inStoryboard:GetSocialStoryboardActivityFeed];
    vc.delegate = self;
    [self.mainNavigationController pushViewController:vc animated:YES];
}

- (void)authorizeWithSuccess:(void (^)(void))success
{
    [self showAlertToChooseAuthorizationOptionToPerform:^{
        success();
    }];
}

#pragma mark - Notifications

- (void)openNotifications
{
    NotificationsViewController *vc = [UIStoryboard viewControllerForName:@"Notifications" inStoryboard:GetSocialStoryboardNotifications];
    [self.mainNavigationController pushViewController:vc animated:YES];
}

- (void)sendNotification
{
    [self.mainNavigationController
        pushViewController:[UIStoryboard viewControllerForName:@"SendNotification" inStoryboard:GetSocialStoryboardNotifications]
                  animated:YES];
}

- (void)showNotificationCenterUI
{
    GetSocialUINotificationCenterView *ncView = [GetSocialUI createNotificationCenterView];
    [ncView setClickHandler:^BOOL(GetSocialNotification *notification) {
        return [self handleAction:notification.notificationAction];
    }];
    [ncView setActionButtonHandler:^BOOL(GetSocialNotification *notification, GetSocialActionButton *actionButton) {
        GSLogInfo(NO, YES, @"Action button [%@] for notification [%@] clicked", actionButton.actionId, notification.notificationId);
        return NO;
    }];
    [ncView show];
}

- (void)sendLocalNotification
{
    UNMutableNotificationContent *notificationContent = [UNMutableNotificationContent new];
    notificationContent.body = @"Amazing local push notification";
    notificationContent.title = @"Check this out!";

    NSString *pnId = [NSUUID UUID].UUIDString;
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:pnId content:notificationContent trigger:trigger];

    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                           withCompletionHandler:^(NSError *_Nullable error) {
                                                               if (error == nil)
                                                               {
                                                                   GSLogInfo(YES, NO, @"PN was sent, it arrives in 5 seconds");
                                                               }
                                                               else
                                                               {
                                                                   GSLogError(YES, NO, @"Sending PN failed, error: %@", [error description]);
                                                               }
                                                           }];
}

#pragma mark - Promo Codes

- (void)showMyPromoCode
{
    if ([GetSocialUser hasPrivatePropertyForKey:@"my_promo_code"])
    {
        [self showPromoCodeInfo:[GetSocialUser privatePropertyValueForKey:@"my_promo_code"]];
    }
    else
    {
        [self showActivityIndicatorView];
        GetSocialPromoCodeBuilder *builder = [GetSocialPromoCodeBuilder withRandomCode];
        [builder addDataValue:@"true" forKey:@"my_promo_code"];
        [GetSocial createPromoCode:builder
            success:^(GetSocialPromoCode *_Nonnull promoCode) {
                [GetSocialUser setPrivatePropertyValue:promoCode.code
                    forKey:@"my_promo_code"
                    success:^{
                        [self hideActivityIndicatorView];
                        [self showMyPromoCode];
                    }
                    failure:^(NSError *_Nonnull error) {
                        [self hideActivityIndicatorView];
                        GSLogError(YES, NO, @"Error setting custom property: %@", error.localizedDescription);
                    }];
            }
            failure:^(NSError *_Nonnull error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Error creating promo code: %@", error.localizedDescription);
            }];
    }
}

- (void)showPromoCodeInfo:(NSString *)code
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Promo Code"
                                                                                    message:code
                                                                          cancelButtonTitle:@"Dismiss"
                                                                          otherButtonTitles:@[ @"Share", @"Copy", @"Info" ]];
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            switch (selectedIndex)
            {
                case 0:
                    [MainViewController sharePromoCode:code];
                    break;

                case 1:
                    [MainViewController copyCode:code];
                    break;

                case 2:
                    [self showActivityIndicatorView];
                    [GetSocial getPromoCode:code
                        success:^(GetSocialPromoCode *_Nonnull promoCode) {
                            [self hideActivityIndicatorView];
                            [MainViewController showPromoCodeFullInfo:promoCode];
                        }
                        failure:^(NSError *_Nonnull error) {
                            [self hideActivityIndicatorView];
                            GSLogError(YES, NO, @"Error getting promo code: %@", error.localizedDescription);
                        }];
                    break;
            }
        }
    }];
}

- (void)createPromoCode
{
    UIViewController *viewController = [UIStoryboard viewControllerForName:@"create_promo_code" inStoryboard:GetSocialStoryboardPromoCodes];
    [self.mainNavigationController pushViewController:viewController animated:YES];
}

- (void)claimPromoCode
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Claim Promo Code"
                                                                                    message:@"Enter promo code to claim"
                                                                          cancelButtonTitle:@"Dismiss"
                                                                          otherButtonTitles:@[ @"Claim" ]];
    [alert addTextFieldWithPlaceholder:@"Promo code..." defaultText:@"" isSecure:NO];
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            [self showActivityIndicatorView];
            NSString *promoCode = [alert contentOfTextFieldAtIndex:0];
            [GetSocial claimPromoCode:promoCode
                success:^(GetSocialPromoCode *_Nonnull promoCode) {
                    [self hideActivityIndicatorView];
                    [self showAlertWithTitle:@"Claimed Promo Code" andText:[MainViewController formatPromoCode:promoCode]];
                }
                failure:^(NSError *_Nonnull error) {
                    [self hideActivityIndicatorView];
                    GSLogError(YES, NO, @"Error claiming promo code: %@", error.localizedDescription);
                }];
        }
    }];
}

- (void)getPromoCodeInfo
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Promo Code Info"
                                                                                    message:@"Enter promo code"
                                                                          cancelButtonTitle:@"Dismiss"
                                                                          otherButtonTitles:@[ @"Info" ]];
    [alert addTextFieldWithPlaceholder:@"Promo code..." defaultText:@"" isSecure:NO];
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            [self showActivityIndicatorView];
            NSString *promoCode = [alert contentOfTextFieldAtIndex:0];
            [GetSocial getPromoCode:promoCode
                success:^(GetSocialPromoCode *_Nonnull promoCode) {
                    [self hideActivityIndicatorView];
                    [self showAlertWithTitle:@"Promo Code" andText:[MainViewController formatPromoCode:promoCode]];
                }
                failure:^(NSError *_Nonnull error) {
                    [self hideActivityIndicatorView];
                    GSLogError(YES, NO, @"Error getting promo code: %@", error.localizedDescription);
                }];
        }
    }];
}

+ (void)sharePromoCode:(NSString *)code
{
    GetSocialUIInvitesView *invitesView = [GetSocialUI createInvitesView];
    GetSocialMutableInviteContent *inviteContent = [GetSocialMutableInviteContent new];
    inviteContent.text = [NSString stringWithFormat:@"Use my Promo Code to get a personal discount %@ . %@",
                                                    GetSocial_InviteContentPlaceholder_Promo_Code, GetSocial_InviteContentPlaceholder_App_Invite_Url];
    [invitesView setCustomInviteContent:inviteContent];
    [invitesView setLinkParams:@{GetSocial_PromoCode : code}];
    [invitesView show];
}

+ (void)copyCode:(NSString *)code
{
    [UIPasteboard generalPasteboard].string = code;
}

+ (void)showPromoCodeFullInfo:(GetSocialPromoCode *)promoCode
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Promo Code"
                                                                                    message:[MainViewController formatPromoCode:promoCode]
                                                                          cancelButtonTitle:@"Dismiss"
                                                                          otherButtonTitles:@[ @"Share", @"Copy" ]];
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            switch (selectedIndex)
            {
                case 0:
                    [self sharePromoCode:promoCode.code];
                    break;

                case 1:
                    [self copyCode:promoCode.code];
                    break;
            }
        }
    }];
}

+ (NSString *)formatPromoCode:(GetSocialPromoCode *)promoCode
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"HH:mm:ss, dd MMM yyy zzz"];
    return [NSString stringWithFormat:
                         @"code: %@"
                          "\ndata: %@"
                          "\nmaxClaim: %u"
                          "\nclaimCount: %u"
                          "\nstartDate: %@"
                          "\nendDate: %@"
                          "\nenabled: %@"
                          "\nclaimable: %@"
                          "\ncreator: %@",
                         promoCode.code, promoCode.data, promoCode.maxClaimCount, promoCode.claimCount,
                         [dateFormatter stringFromDate:promoCode.startDate], [dateFormatter stringFromDate:promoCode.endDate],
                         promoCode.enabled ? @"true" : @"false", promoCode.claimable ? @"true" : @"false", promoCode.creator.displayName];
}

#pragma mark - Localization

- (BOOL)changeLanguage:(NSString *)language
{
    [GetSocial setLanguage:language];
    self.languageMenu.detail = [NSString stringWithFormat:@"Current language: %@", [GetSocialConstants allLanguageCodes][language]];
    GSLogInfo(NO, NO, @"Language changed to: %@.", language);
    return YES;
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    if (picker == self.avatarImagePicker)
    {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        image = [image imageByResizeAndKeepRatio:CGSizeMake(MAX_WIDTH, MAX_HEIGHT)];

        [self showActivityIndicatorView];
        [GetSocialUser setAvatar:image
            success:^{
                [self hideActivityIndicatorView];
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
                GSLogInfo(YES, NO, @"User avatar has been successfully updated");
            }
            failure:^(NSError *error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Error changing user avatar: %@", error.localizedDescription);
            }];
        [self.avatarImagePicker dismissViewControllerAnimated:YES completion:nil];
        self.avatarImagePicker = nil;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (picker == self.avatarImagePicker)
    {
        [self.avatarImagePicker dismissViewControllerAnimated:YES completion:nil];
        self.avatarImagePicker = nil;
    }
}

#pragma mark - UI Customization

- (BOOL)loadDefaultUI
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];

    [GetSocialUI loadDefaultConfiguration];

    self.uiCustomizationMenu.detail = @"Current UI: Default";
    return YES;
}

- (BOOL)loadDefaultUILandscape
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeLeft) forKey:@"orientation"];

    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"ui-config" ofType:@"json" inDirectory:@"getsocial-default-landscape"];
    if (![GetSocialUI loadConfiguration:configPath])
    {
        NSLog(@"Could not load custom configuration");
        return NO;
    }

    self.uiCustomizationMenu.detail = @"Current UI: Default Landscape";

    return YES;
}

- (BOOL)loadLightUIPortrait
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];

    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"ui-config" ofType:@"json" inDirectory:@"getsocial-light"];
    if (![GetSocialUI loadConfiguration:configPath])
    {
        NSLog(@"Could not load custom configuration");
        return NO;
    }

    self.uiCustomizationMenu.detail = @"Current UI: Light Portrait";

    return YES;
}
- (BOOL)loadLightUILandscape
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeLeft) forKey:@"orientation"];

    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"ui-config" ofType:@"json" inDirectory:@"getsocial-light-landscape"];
    if (![GetSocialUI loadConfiguration:configPath])
    {
        NSLog(@"Could not load custom configuration");
        return NO;
    }

    self.uiCustomizationMenu.detail = @"Current UI: Light Landscape";

    return YES;
}

- (BOOL)loadDarkUIPortrait
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];

    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"ui-config" ofType:@"json" inDirectory:@"getsocial-dark"];
    if (![GetSocialUI loadConfiguration:configPath])
    {
        NSLog(@"Could not load custom configuration");
        return NO;
    }

    self.uiCustomizationMenu.detail = @"Current UI: Dark Portrait";

    return YES;
}

- (BOOL)loadDarkUILandscape
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeLeft) forKey:@"orientation"];

    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"ui-config" ofType:@"json" inDirectory:@"getsocial-dark-landscape"];
    if (![GetSocialUI loadConfiguration:configPath])
    {
        NSLog(@"Could not load custom configuration");
        return NO;
    }

    self.uiCustomizationMenu.detail = @"Current UI: Dark Landscape";

    return YES;
}

#pragma mark - Analytics

- (void)trackCustomEventWithName:(NSString *)eventName properties:(NSDictionary *)properties
{
    if ([GetSocial trackCustomEventWithName:eventName eventProperties:properties])
    {
        GSLogInfo(YES, NO, @"Custom event was tracked.");
    }
    else
    {
        GSLogInfo(YES, NO, @"Failed to track custom event.");
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.mainNavigationController = [segue destinationViewController];
    self.mainNavigationController.menu = self.menu;
    self.mainNavigationController.delegate = self;
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[MenuTableViewController class]])
    {
        [self updateFriendsCount];
    }
}

@end
