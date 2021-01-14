/*
 *        Copyright 2015-2020 GetSocial B.V.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
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

#import <GetSocialSDK/GetSocialSDK.h>
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
//#import "MessagesController.h"
#import "PushNotificationView.h"
#import "UIImage+GetSocial.h"
#import "UIStoryboard+GetSocial.h"

#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <UserNotifications/UserNotifications.h>
#if ANALYTICS_DEMO == 1
#import "GetSocialAnalyticsApp-Swift.h"
#elif AUTOMATION_TEST == 1
#import "GetSocialAutomationTests-Swift.h"
#elif INTERNAL_DEMO == 1
#import "GetSocialInternalDemo-Swift.h"
#else
#import "GetSocialDemo-Swift.h"
#endif

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
    [GetSocialNotifications setOnTokenReceivedListener:^(NSString *_Nonnull deviceToken) {
        [[ConsoleViewController sharedController] log:LogLevelInfo
                                              message:[NSString stringWithFormat:@"Device Push Token: %@", deviceToken]
                                              context:@"PushNotificationHandler"];
    }];
    [GetSocialNotifications setOnNotificationClickedListener:^(GetSocialNotification *notification, GetSocialNotificationContext* context) {
        [self handleNotification:notification withContext:context];
    }];
    [GetSocial addOnCurrentUserChangedListener:^(GetSocialCurrentUser* newUser) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        [self updateFriendsCount];
    }];

    [GetSocial addOnInitializedListener:^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        if (self.chatIdToShow)
        {
            // TODO: REMOVED UNTIL BACKEND IS READY
//            [self showChatView];
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

- (void)handleNotification:(GetSocialNotification *)notification withContext:(GetSocialNotificationContext *)context
{
    GetSocialAction *action = notification.notificationAction;
    NSString* status = GetSocialNotificationStatus.read;

    if (context.action == nil) {
        [self handleAction:action];
    } else if ([context.action isEqualToString:GetSocialNotificationButton.actionIdConsume])
    {
        [GetSocial handleAction:action];
        if ([action.type isEqualToString:GetSocialActionType.addFriend])
        {
            NSString *userName = action.data[@"user_name"];
            [self showAlertWithText:[NSString stringWithFormat:@"%@ added to friends.", userName]];
        }
    }
    else if ([context.action isEqualToString:GetSocialNotificationButton.actionIdIgnore])
    {
        status = GetSocialNotificationStatus.ignored;
    }
    [GetSocialNotifications setStatusTo:status
                      notificationIds: @[ notification.notificationId ]
        success:^{
            NSLog(@"Successfully updated notification");
        }
        failure:^(NSError *error) {
            NSLog(@"Failed to update notification, error: %@", error.localizedDescription);
        }];
}

- (void)handleAction:(GetSocialAction *)action
{
    if ([action.type isEqualToString:GetSocialActionType.openProfile])
    {
        self.userIdToShow = action.data[GetSocialActionDataKey.openProfile_UserId];
        if (GetSocial.isInitialized && self.userIdToShow != nil)
        {
            [self showNewFriend];
        }
        return;
    }
    if ([action.type isEqualToString:GetSocialActionType.claimPromoCode])
    {
        [self showActivityIndicatorView];
        [GetSocialPromoCodes claimWithCode:action.data[GetSocialActionDataKey.claimPromoCode_PromoCode]
            success:^(GetSocialPromoCode *_Nonnull promoCode) {
                [self hideActivityIndicatorView];
                [self showAlertWithTitle:@"Claimed Promo Code" andText:[MainViewController formatPromoCode:promoCode]];
            }
            failure:^(NSError *_Nonnull error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Error claiming promo code: %@", error.localizedDescription);
            }];
        return;
    }
    if ([action.type isEqualToString:GetSocialActionType.addFriend]) {
        [self showAlertWithText:@"Add friend action was handled"];
        return;
    }
    if ([action.type isEqualToString:@"custom"])
    {
        [self showAlertWithText:@"Custom action was handled"];
        return;
    }
    if ([action.type isEqualToString:@"DEFAULT"] || [action.type isEqualToString:@"default"])
    {
        [self showAlertWithText:@"DEFAULT action was handled"];
        return;
    }
    if ([action.type isEqualToString:GetSocialActionType.openChat]) {
        [self openChatWithId:action.data[GetSocialActionDataKey.openChat_ChatId]];
        return;
    }
    [GetSocial handleAction:action];
}

- (GetSocialActionHandler)defaultActionHandler
{
    return ^void(GetSocialAction *action) {
        [self handleAction:action];
    };
}

- (void)registerInviteChannelPlugins
{
    // Register FB Messenger Invite Plugin
    GetSocialFBMessengerInvitePlugin *fbMessengerPlugin = [[GetSocialFBMessengerInvitePlugin alloc] init];
    [GetSocialInvites registerPlugin:fbMessengerPlugin forChannel:GetSocialInviteChannelIds.facebookMessenger];

    // Register KakaoTalk Invite Plugin
    GetSocialKakaoTalkInvitePlugin *kakaoTalkPlugin = [[GetSocialKakaoTalkInvitePlugin alloc] init];
    [GetSocialInvites registerPlugin:kakaoTalkPlugin forChannel:GetSocialInviteChannelIds.kakao];

#if DISABLE_TWITTER != 1
    // Register Twitter Invite Plugin
    GetSocialTwitterInvitePlugin *twitterPlugin = [[GetSocialTwitterInvitePlugin alloc] init];
    [GetSocialInvites registerPlugin:twitterPlugin forChannel:GetSocialInviteChannelIds.twitter];
#endif
    // Register Facebook Share Plugin
    GetSocialFacebookSharePlugin *fbSharePlugin = [[GetSocialFacebookSharePlugin alloc] init];
    [GetSocialInvites registerPlugin:fbSharePlugin forChannel:GetSocialInviteChannelIds.facebook];

    // Register VK Invite Plugin
    GetSocialVKInvitePlugin *vkInvitePlugin = [[GetSocialVKInvitePlugin alloc] init];
    [GetSocialInvites registerPlugin:vkInvitePlugin forChannel:GetSocialInviteChannelIds.vk];

    // Register Instagram Stories Plugin
    GetSocialInstagramStoriesInviteChannel *igStoriesPlugin = [GetSocialInstagramStoriesInviteChannel new];
    [GetSocialInvites registerPlugin:igStoriesPlugin forChannel:GetSocialInviteChannelIds.instagramStories];
}

- (void)updateFriendsCount
{
    if (![GetSocial isInitialized])
    {
        return;
    }
    GetSocialFriendsQuery* query = [GetSocialFriendsQuery ofUserWithId:[GetSocialUserId create: GetSocial.currentUser.userId]];
    [GetSocialCommunities friendsCountWithQuery:query success:^(NSInteger result) {
        self.friendsMenu.detail = [NSString stringWithFormat:@"You have %ld friends", result];
    }
    failure:^(NSError *error) {
        GSLogError(NO, NO, @"Error updating friends count: %@", error.localizedDescription);
    }];

    NSArray<NSString *> *statuses = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_statuses"];
    NSArray<NSString *> *types = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_types"];
    NSArray<NSString *> *actions = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_actions"];

    GetSocialNotificationsQuery *notificationsQuery =
        statuses ? [GetSocialNotificationsQuery withStatuses:statuses] : [GetSocialNotificationsQuery withAllStatuses];

    if (types) [notificationsQuery setTypes:types];
    if (actions) [notificationsQuery setActions:actions];

    [GetSocialNotifications countWithQuery:notificationsQuery
        success:^(NSInteger result) {
            self.notificationsMenu.detail = [NSString stringWithFormat:@"You have %ld notifications", result];
        }
        failure:^(NSError *error) {
            GSLogError(NO, NO, @"Error updating notifications count: %@", error.localizedDescription);
        }];

    [GetSocialNotifications arePushNotificationsEnabledWithSuccess:^(BOOL result) {
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
        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Reset without init"
                                                                               action:^{
            [self resetWithoutInit];
                                                                               }]];
        
        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Init with anonymous user"
                                                                               action:^{
            if ([GetSocial isInitialized]) {
                GSLogInfo(YES, NO, @"Already initialized, call resetWithoutInit first");
                return;
            }
            [GetSocial initSdk];
            [GetSocial addOnInitializedListener:^{
                
                GSLogInfo(YES, NO, @"Anonymous User logged in");
            }];
            
                                                                               }]];
        
        [self.userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Init with..."
                                                                               action:^{
            [self initWithIdentity];
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
        self.activitiesMenu = [MenuItem parentMenuItemWithTitle:@"Activities"];

        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Timeline"
                                                      action:^{
                                                        GetSocialActivitiesQuery* query = [GetSocialActivitiesQuery timeline];
            [self showActivitiesViewWithQuery:query];

                                                      }]];

        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"All my posts"
                                                      action:^{
            GetSocialActivitiesQuery* query = [[GetSocialActivitiesQuery everywhere] byUserWithId: GetSocialUserId.currentUser];
            [self showActivitiesViewWithQuery:query];

                                                      }]];

        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"My feed"
                                                      action:^{
            GetSocialActivitiesQuery* query = [GetSocialActivitiesQuery feedOfUserWithId: GetSocialUserId.currentUser];
            [self showActivitiesViewWithQuery:query];

                                                      }]];

        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post to timeline"
                                                      action:^{
            GetSocialPostActivityTarget* target = [GetSocialPostActivityTarget timeline];
            [self openPostActivityView:target];

                                                      }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Topic Activity Feed (DemoFeed)"
                                                                       action:^{
            GetSocialActivitiesQuery* query = [GetSocialActivitiesQuery inTopicWithId:@"DemoFeed"];
                                                                           [self showActivitiesViewWithQuery:query];
                                                                       }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"My Feed"
                                                                       action:^{
            GetSocialActivitiesQuery* query = [GetSocialActivitiesQuery feedOfUserWithId: GetSocialUserId.currentUser];
            [self showActivitiesViewWithQuery:query];
                                                                       }]];
        [self.activitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Edit Activity"
                                                      action:^{
                                                            [self showChooseActivityAlert];
                                                      }]];

                // TODO: put this back later
        //        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Activity Details"
        //                                                                       action:^{
        //                                                                           [self showChooseActivityAlert:YES];
        //                                                                       }]];
        //
        //        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Activity Details(without activity feed)"
        //                                                                       action:^{
        //                                                                           [self showChooseActivityAlert:NO];
        //                                                                       }]];


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

        [self.notificationsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Notification Center UI with Click Handler"
                                                                          action:^{
                                                                              [self showNotificationCenterUIWithHandlers];
                                                                          }]];

        // Topics
        MenuItem *topicsMenu = [MenuItem actionableMenuItemWithTitle:@"Topics"
                                                              action:^{
                                                                  [self showTopics];
                                                              }];
        [self.menu addObject:topicsMenu];

        // Groups
        ParentMenuItem* groupsMenu = [MenuItem parentMenuItemWithTitle:@"Groups"];
        MenuItem *createGroups = [MenuItem actionableMenuItemWithTitle:@"Create"
                                                              action:^{
                                                                  [self createGroups];
                                                              }];
        [groupsMenu addSubmenu:createGroups];

        MenuItem *groupsList = [MenuItem actionableMenuItemWithTitle:@"Search"
                                                              action:^{
                                                                  [self showGroups];
                                                              }];
        [groupsMenu addSubmenu:groupsList];
        MenuItem *myGroups = [MenuItem actionableMenuItemWithTitle:@"My Groups"
                                                              action:^{
                                                                  [self showMyGroups];
                                                              }];
        [groupsMenu addSubmenu:myGroups];

        [self.menu addObject:groupsMenu];

        // Chats

        MenuItem *chatsList = [MenuItem actionableMenuItemWithTitle:@"Chats"
                                                              action:^{
                                                                  [self showChats];
                                                              }];
        [self.menu addObject: chatsList];


        // Users
        MenuItem *usersMenu = [MenuItem actionableMenuItemWithTitle:@"Users"
                                                              action:^{
                                                                  [self showUsers];
                                                              }];
        [self.menu addObject:usersMenu];

        // Users by Ids
        MenuItem *usersByIdMenu = [MenuItem actionableMenuItemWithTitle:@"Users by Id"
                                                              action:^{
                                                                  [self showUsersById];
                                                              }];
        [self.menu addObject:usersByIdMenu];

        // Tags
        MenuItem *tagsMenu = [MenuItem actionableMenuItemWithTitle:@"Tags"
                                                              action:^{
                                                                  [self showTags];
                                                              }];
        [self.menu addObject:tagsMenu];

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

        NSDictionary *availableLanguages = [GetSocialLanguageCodes all];

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
                                              [GetSocialNotifications setPushNotificationsEnabled:isChecked
                                                  success:^{
                                                      self.pushNotificationsEnabledMenu.isChecked = isChecked;
                                                  }
                                                  failure:^(NSError *error) {
                                                      NSLog(@"Failed to change PN status, %@", error.localizedDescription);
                                                  }];
                                              return NO;
                                          }];
        [self.settingsMenu addSubmenu:self.pushNotificationsEnabledMenu];
        
        // Enable/Disable custom errors
        [self.settingsMenu addSubmenu: [MenuItem checkableMenuItemWithTitle:@"Enable Custom Errors"
                                                                 isChecked:NO
                                                                    action:^BOOL(BOOL isChecked) {
            self.showCustomErrorMessages = !self.showCustomErrorMessages;
            return YES;
        }]];

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

- (void)showActivitiesViewWithQuery:(GetSocialActivitiesQuery*)query {
      GetSocialUIActivityFeedView *activityFeedView = [GetSocialUIActivityFeedView viewForQuery: query];
      [activityFeedView setActionHandler:[self defaultActionHandler]];
    if (self.showCustomErrorMessages) {
            [activityFeedView setCustomErrorMessageProvider:^NSString *(NSInteger errorCode, NSString *errorMessage) {
                if (errorCode == GetSocialErrorCode.ActivityRejected) {
                    return @"Be careful what you say :)";
                } else {
                    return errorMessage;
                }
            }];
        }
      [activityFeedView setHandlerForViewOpen:^() {
          NSLog(@"Timeline is opened");
      }
          close:^() {
              NSLog(@"Timeline is closed");
          }];
      [activityFeedView setAvatarClickHandler:^(GetSocialUser *user) {
          [self didClickOnUser:user];
      }];
      [activityFeedView setMentionClickHandler:^(NSString* mention) {
          if ([mention isEqualToString:GetSocialUI_Shortcut_App])
          {
              [self showAlertWithText:@"Application mention clicked."];
              return;
          }
          GetSocialUserIdList* userIdList = [GetSocialUserIdList create: @[mention]];
          [GetSocialCommunities usersWithIds:userIdList success:^(NSDictionary<NSString *,GetSocialUser *> * users) {
              [self didClickOnUser:users.allValues.firstObject];

          } failure:^(NSError * error) {
              NSLog(@"Failed to get user, error: %@", error.localizedDescription);
          }];
      }];
      [activityFeedView setTagClickHandler:^(NSString *tagName) {
          [self showAlertWithText:[NSString stringWithFormat: @"[%@] tag was clicked", tagName]];
      }];
      [activityFeedView setUiActionHandler:^(GetSocialUIActionType actionType,
                                             GetSocialUIPendingAction pendingAction) {
          switch (actionType)
          {
              case GetSocialUIActionLikeActivity:
              case GetSocialUIActionLikeComment:
              case GetSocialUIActionPostActivity:
              case GetSocialUIActionPostComment:
                  if (GetSocial.currentUser.isAnonymous)
                  {
                      [self showAlertToChooseAuthorizationOptionToPerform:pendingAction];
                      break;
                  }
              default:
                  pendingAction();
          }
      }];
      [activityFeedView show];
}

- (void)didClickOnUser:(GetSocialUser *)user
{
    if ([user.userId isEqualToString:GetSocial.currentUser.userId])
    {
        [self showActionDialogForCurrentUser:user];
        return;
    }
    [GetSocialCommunities areFriendsWithIds:[GetSocialUserIdList create: @[user.userId]]
        success:^(NSDictionary<NSString*, NSNumber*>* result) {
            if (result.allValues.firstObject.boolValue)
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

- (void)showGlobalFeedForUser:(NSString*)userId withTitle:(NSString *)title
{
    NSLog(@"Not implemented in phase 1");
//    GetSocialUIActivityFeedView *activityFeedView = [GetSocialFeedsUI createGlobalActivityFeedView];
//    [activityFeedView setActionHandler:[self defaultActionHandler]];
//    [activityFeedView setWindowTitle:title];
//    [activityFeedView setReadOnly:YES];
//    [activityFeedView setFilterByUser:userId];
//    [activityFeedView show];
}

- (void)showActionDialogForCurrentUser:(GetSocialUser *)user
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:@"Choose action"
                                                   message:[NSString stringWithFormat:@"Choose one of possible actions"]
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:nil];
    [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            // FIXME: put back when backend ready
            [self showAlertWithText:@"Feature is not implemented in backend yet"];
            //[self showGlobalFeedForUser:user.userId withTitle:@"My Global Feed"];
        }
    }];
}

- (void)showActionDialogForFriend:(GetSocialUser *)user
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:[NSString stringWithFormat:@"User [%@]", user.displayName]
                                                   message:[NSString stringWithFormat:@"Choose one of possible actions"]
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@[ @"Remove from Friends", @"Open Chat"]];

    [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            switch (selectedIndex)
            {
                case 0: {
                    [GetSocialCommunities removeFriendsWithIds:[GetSocialUserIdList create: @[user.userId]]
                        success:^(NSInteger friendsCount) {
                            [self showAlertWithText:[NSString stringWithFormat:@"%@ removed from friends.", user.displayName]];
                        }
                        failure:^(NSError *error) {
                            NSLog(@"Failed to remove friend, error: %@", error.localizedDescription);
                        }];
                    break;
                }
                case 1: {
                    [self openChatWithUser: user.userId];
                    break;
                }
            }
        }
    }];
}

- (void)showActionDialogForNonFriend:(GetSocialUser *)user
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:[NSString stringWithFormat:@"User [%@]", user.displayName]
                                                   message:[NSString stringWithFormat:@"Choose one of possible actions"]
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@[ @"Add to Friends", @"Open Chat" ]];

    [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            switch (selectedIndex)
            {
                case 0: {
                    [GetSocialCommunities addFriendsWithIds:[GetSocialUserIdList create: @[user.userId]]
                        success:^(NSInteger friendsCount) {
                            [self showAlertWithText:[NSString stringWithFormat:@"%@ added to friends.", user.displayName]];
                        }
                        failure:^(NSError *error) {
                            NSLog(@"Failed to add friend, error: %@", error.localizedDescription);
                        }];
                    break;
                }
                case 1: {
                    [self openChatWithUser: user.userId];
                    break;
                }
            }
        }
    }];
}

- (void)showChooseActivityAlert
{
    GetSocialActivitiesQuery *query = [[GetSocialActivitiesQuery everywhere] byUserWithId:[GetSocialUserId currentUser]];
    GetSocialActivitiesPagingQuery* pagingQuery = [[GetSocialActivitiesPagingQuery alloc] initWithQuery:query];

    [GetSocialCommunities activitiesWithQuery:pagingQuery success:^(GetSocialActivitiesPagingResult * result) {
        NSMutableArray *activities = [NSMutableArray new];
        NSMutableArray *activityContents = [NSMutableArray new];
        for (GetSocialActivity *activity in result.activities)
        {
            if ([activity.author.userId isEqualToString:GetSocial.currentUser.userId]) {
                [activities addObject:activity];
                NSString* text = activity.text != nil ? activity.text : activity.activityId;
                [activityContents addObject:text];
            }
        }
        UISimpleAlertViewController *alertViewController =
            [[UISimpleAlertViewController alloc] initWithTitle:@"Activity ID"
                                                       message:@"Select an activity ID to be displayed"
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:activityContents];
        [alertViewController showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                PostActivityViewController* pavc = [UIStoryboard viewControllerForName:@"PostActivity" inStoryboard:GetSocialStoryboardActivityFeed];
                pavc.activityToUpdate = activities[selectedIndex];
                [self.mainNavigationController pushViewController:pavc animated:YES];
            }
        }];

    } failure:^(NSError * error) {
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
    GetSocialUserUpdate* userUpdate = [GetSocialUserUpdate new];
    [userUpdate setAvatarUrl:[UserIdentityUtils randomAvatarUrl]];
    [GetSocial.currentUser updateDetailsWith: userUpdate
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
            GetSocialUserUpdate* userUpdate = [GetSocialUserUpdate new];
            [userUpdate setPublicPropertyValue:value forKey:key];
            [GetSocial.currentUser updateDetailsWith: userUpdate
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

            NSString *value = [GetSocial.currentUser.publicProperties valueForKey:key];
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
            GetSocialUserUpdate* userUpdate = [GetSocialUserUpdate new];
            [userUpdate setDisplayName: newDisplayName];
            [GetSocial.currentUser updateDetailsWith: userUpdate
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
    NSDictionary *authIdentities = [GetSocial.currentUser identities];
    if (!authIdentities[GetSocialIdentityProviderIds.facebook])
    {
        [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
        [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *loginError) {
            if (!loginError && !result.isCancelled)
            {
                [self addIdentity:[GetSocialIdentity facebookIdentityWithAccessToken:result.token.tokenString]
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

    GetSocialUserUpdate* userUpdate = [GetSocialUserUpdate new];
    [userUpdate setAvatarUrl:profileImageUrl.absoluteString];

    [GetSocial.currentUser updateDetailsWith:userUpdate
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

    GetSocialUserUpdate* userUpdate = [GetSocialUserUpdate new];
    [userUpdate setDisplayName: displayName];

    [GetSocial.currentUser updateDetailsWith: userUpdate
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
    if ([GetSocial.currentUser identities][GetSocialIdentityProviderIds.facebook])
    {
        [self showActivityIndicatorView];
        [GetSocial.currentUser removeIdentityByProviderId:GetSocialIdentityProviderIds.facebook
            success:^{
                [self hideActivityIndicatorView];
                GSLogInfo(YES, NO, @"Identity removed for Provider %@.", GetSocialIdentityProviderIds.facebook);
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            }
            failure:^(NSError *error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Failed to remove Identity for Provider %@, error: %@", GetSocialIdentityProviderIds.facebook,
                           [error localizedDescription]);
            }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User doesn't have UserIdentity for Provider %@.", GetSocialIdentityProviderIds.facebook);
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

            GetSocialIdentity *identity =
                [GetSocialIdentity customIdentityWithProviderId:providerId userId:providerUserId accessToken:accessToken];

            [self addIdentity:identity success:success failure:failure];
        }
    }];
}

- (void)removeCustomUserIdentity
{
    if ([GetSocial.currentUser identities][kCustomProvider])
    {
        [self showActivityIndicatorView];
        [GetSocial.currentUser removeIdentityByProviderId:kCustomProvider
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
    [GetSocial resetUserWithSuccess:^() {
        [self hideActivityIndicatorView];
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];

        GSLogInfo(YES, NO, @"User was successfully logged out.");
    }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            GSLogError(YES, NO, @"Failed to log out user, error: %@", [error localizedDescription]);
        }];
}

- (void)resetWithoutInit
{
    [self showActivityIndicatorView];
    [GetSocial resetWithSuccess:^{
        [self hideActivityIndicatorView];
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];

        GSLogInfo(YES, NO, @"User was successfully logged out.");
    } failure:^(NSError * _Nonnull error) {
        [self hideActivityIndicatorView];
         GSLogError(YES, NO, @"Failed to log out user, error: %@", [error localizedDescription]);
    }];
}
     
- (void)initWithIdentity
{
    if ([GetSocial isInitialized]) {
        GSLogInfo(YES, NO, @"Already initialized, call resetWithoutInit first");
        return;
    }
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc]
        initWithTitle:@"Init with..."
              message:@"Init with custom identity of FB"
    cancelButtonTitle:@"Cancel"
    otherButtonTitles:@[ @"FB", @"Custom" ]];
    
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (didCancel) {
            return;
        }
        if (selectedIndex == 1) {
            [self initWithCustom];
        } else {
            [self initWithFB];
        }
    }];
}

- (void)initWithCustom
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
            [self showActivityIndicatorView];
            NSString *providerId = kCustomProvider;
            NSString *providerUserId = [alert contentOfTextFieldAtIndex:0];
            NSString *accessToken = [alert contentOfTextFieldAtIndex:1];

            GetSocialIdentity *identity =
                [GetSocialIdentity customIdentityWithProviderId:providerId userId:providerUserId accessToken:accessToken];

            [GetSocial initSdkWithIdentity:identity
                      success:^{
                          [self hideActivityIndicatorView];
                          GSLogInfo(YES, NO, @"User %@ logged in", identity);
                      }
                                failure:^(NSError * _Nonnull error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Error init with identity: %@", error.localizedDescription);
            }];
        }
    }];
}

- (void)initWithFB
{
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *loginError) {
        if (!loginError && !result.isCancelled)
        {
            [self showActivityIndicatorView];
            [GetSocial initSdkWithIdentity:[GetSocialIdentity facebookIdentityWithAccessToken:result.token.tokenString]
                      success:^{
                          [self setFacebookDisplayName];
                          [self setFacebookAvatar];
                          [self hideActivityIndicatorView];
                          GSLogInfo(YES, NO, @"User FB identity logged in");
                      }
                                failure:^(NSError * _Nonnull error) {
                [self hideActivityIndicatorView];
                GSLogError(YES, NO, @"Error init with identity: %@", error.localizedDescription);
            }];
        }
    }];
}


- (void)addIdentity:(GetSocialIdentity *)identity success:(void (^)(void))success failure:(void (^)(void))failure
{
    [self showActivityIndicatorView];
    [GetSocial.currentUser addIdentity:identity
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

- (void)callSwitchUserWithIdentity:(GetSocialIdentity *)identity success:(void (^)(void))success failure:(void (^)(void))failure
{
    [self showActivityIndicatorView];
    [GetSocial switchUserToIdentity:identity
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
        otherButtonTitles:@[ [NSString stringWithFormat:@"%@ (Current)", GetSocial.currentUser.userId] ]];

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
    [GetSocialCommunities usersWithIds:[GetSocialUserIdList create: @[self.userIdToShow]]
        success:^(NSDictionary<NSString*, GetSocialUser*>* result) {
            NewFriendViewController *newFriendViewController =
                [UIStoryboard viewControllerForName:@"NewFriendViewController" inStoryboard:GetSocialStoryboardSocialGraph];
            [newFriendViewController setPublicUser:result.allValues.firstObject];
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
    [[GetSocialUIInvitesView new] show];
}

- (void)checkReferralData
{
    [GetSocialInvites setOnReferralDataReceivedListener:^(GetSocialReferralData * referralData) {
            NSMutableString *linkParams = [NSMutableString new];
            [referralData.linkParams enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop)
            {
                [linkParams appendFormat:@"%@ = %@, ", key, obj];
            }];
            NSString *promoCode = nil; //referralData.referralLinkParams[GetSocial_PromoCode];
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
                    [GetSocialPromoCodes claimWithCode: promoCode
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
            GetSocialReferralUsersPagingQuery* pagingQuery = [[GetSocialReferralUsersPagingQuery alloc] initWithQuery:query];
            [GetSocialInvites referredUsersWithQuery:pagingQuery success:^(GetSocialReferralUsersPagingResult* result) {
                        [self hideActivityIndicatorView];
                        __block NSString *messageContent = @"No referred users";
                        if (result.users.count > 0)
                        {
                            messageContent = @"";
                            [result.users enumerateObjectsUsingBlock:^(GetSocialReferralUser *_Nonnull referralUser, NSUInteger idx, BOOL *_Nonnull stop) {
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
            GetSocialReferralUsersPagingQuery* pagingQuery = [[GetSocialReferralUsersPagingQuery alloc] initWithQuery:query];
            [GetSocialInvites referrerUsersWithQuery:pagingQuery success:^(GetSocialReferralUsersPagingResult* result) {
                        [self hideActivityIndicatorView];
                        __block NSString *messageContent = @"No referrer users";
                        if (result.users.count > 0)
                        {
                            messageContent = @"";
                            [result.users enumerateObjectsUsingBlock:^(GetSocialReferralUser *_Nonnull referralUser, NSUInteger idx, BOOL *_Nonnull stop) {
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
    [self showActivityIndicatorView];
    [GetSocialInvites availableChannelsWithSuccess:^(NSArray<GetSocialInviteChannel *> * channels) {
        [self hideActivityIndicatorView];
        NSMutableArray *providerNames = [NSMutableArray array];
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
    } failure:^(NSError * error) {
        [self hideActivityIndicatorView];
    }];
}

- (void)showSetReferrer {
    [self.mainNavigationController
        pushViewController:[UIStoryboard viewControllerForName:@"SetReferrer" inStoryboard:GetSocialStoryboardSmartInvites]
                  animated:YES];
}

- (void)createInviteLink
{
    [GetSocialInvites createInviteWithContent:nil
        success:^(GetSocialInvite* invite) {
            GSLogInfo(YES, NO, @"Created invite url: %@", invite.referralUrl);
        }
        failure:^(NSError *_Nonnull error) {
            GSLogInfo(YES, NO, @"Failed to create invite url, error: %@", error);
        }];
}

- (void)callSendInviteWithProviderId:(NSString *)providerId
{
    [self showActivityIndicatorView];
    [GetSocialInvites sendInviteContent: nil
                                  onChannel: providerId
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

#pragma mark - Tags

- (void)showTags
{
    [CommunitiesHelper showTagsWithNavigationController:self.mainNavigationController];
}


#pragma mark - Topics

- (void)showTopics
{
    [CommunitiesHelper showTopicsWithNavigationController:self.mainNavigationController];
}

#pragma mark - Groups

- (void)createGroups
{
    [CommunitiesHelper showCreateGroupWithNavigationController: self.mainNavigationController];
}

- (void)showGroups
{
    [CommunitiesHelper showGroupsWithNavigationController:self.mainNavigationController];
}

- (void)showMyGroups
{
    [CommunitiesHelper showMyGroupsWithNavigationController:self.mainNavigationController];
}

#pragma mark - Chats

- (void)showChats
{
    [GetSocialUI closeView:NO];
    [CommunitiesHelper showChatsWithNavigationController: self.mainNavigationController];
}

- (void)openChatWithId:(NSString*)chatId
{
    [CommunitiesHelper showChatMessagesWithNavigationController: self.mainNavigationController chatId:chatId];
}

- (void)openChatWithUser:(NSString*)userId
{
    [GetSocialUI closeView:NO];
    [CommunitiesHelper showChatMessagesWithNavigationController: self.mainNavigationController userId:[GetSocialUserId create: userId]];
}


#pragma mark - Users

- (void)showUsers
{
    [CommunitiesHelper showUsersWithNavigationController:self.mainNavigationController];
}

#pragma mark - Users by Id

- (void)showUsersById
{
    [CommunitiesHelper showUsersByIdWithNavigationController:self.mainNavigationController];
}

#pragma mark - Activities

- (void)openPostActivityView:(GetSocialPostActivityTarget*)target
{
    PostActivityViewController *vc = [UIStoryboard viewControllerForName:@"PostActivity" inStoryboard:GetSocialStoryboardActivityFeed];
    if (target != nil) {
        vc.postTarget = target;
    }
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
    GetSocialUINotificationCenterView *ncView = [GetSocialUINotificationCenterView viewForQuery:[GetSocialNotificationsQuery withAllStatuses]];
    [ncView show];
}

- (void)showNotificationCenterUIWithHandlers
{
    GetSocialUINotificationCenterView *ncView = [GetSocialUINotificationCenterView viewForQuery:[GetSocialNotificationsQuery withAllStatuses]];
    [ncView setClickHandler:^void(GetSocialNotification *notification, GetSocialNotificationContext* context) {
        [self handleNotification: notification withContext: context];
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
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       GSLogInfo(YES, NO, @"PN was sent, it arrives in 5 seconds");
                                                                   });
                                                               }
                                                               else
                                                               {
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       GSLogError(YES, NO, @"Sending PN failed, error: %@", [error description]);
                                                                   });
                                                               }
                                                           }];
}

#pragma mark - Promo Codes

- (void)showMyPromoCode
{
    if ([GetSocial.currentUser.privateProperties valueForKey:@"my_promo_code"])
    {
        [self showPromoCodeInfo:[GetSocial.currentUser.privateProperties valueForKey:@"my_promo_code"]];
    }
    else
    {
        [self showActivityIndicatorView];
        GetSocialPromoCodeContent *content = [GetSocialPromoCodeContent withRandomCode];
        NSMutableDictionary* dataValues = [NSMutableDictionary new];
        [dataValues setObject:@"true" forKey:@"my_promo_code"];
        content.properties = dataValues;
        [GetSocialPromoCodes createWithContent:content
            success:^(GetSocialPromoCode *_Nonnull promoCode) {
            GetSocialUserUpdate* update = [GetSocialUserUpdate new];
                [update setPrivatePropertyValue:promoCode.code forKey:@"my_promo_code"];
                [GetSocial.currentUser updateDetailsWith: update
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
                    [GetSocialPromoCodes getWithCode:code
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
            [GetSocialPromoCodes claimWithCode:promoCode
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
            [GetSocialPromoCodes getWithCode:promoCode
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
    GetSocialUIInvitesView *invitesView = [GetSocialUIInvitesView new];
    GetSocialInviteContent *inviteContent = [GetSocialInviteContent new];
    inviteContent.text = [NSString stringWithFormat:@"Use my Promo Code to get a personal discount %@ . %@",
                                                    GetSocialInviteContentPlaceholders.promoCode, GetSocialInviteContentPlaceholders.inviteUrl];
    [inviteContent setLinkParams:@{GetSocialLinkParams.customPromoCode : code}];
    [invitesView setCustomInviteContent:inviteContent];
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
    NSDate* startDate = [NSDate dateWithTimeIntervalSince1970:promoCode.startDate];
    NSDate* endDate = [NSDate dateWithTimeIntervalSince1970:promoCode.endDate];
    return [NSString stringWithFormat:
                         @"code: %@"
                          "\ndata: %@"
                          "\nmaxClaim: %lu"
                          "\nclaimCount: %lu"
                          "\nstartDate: %@"
                          "\nendDate: %@"
                          "\nenabled: %@"
                          "\nclaimable: %@"
                          "\ncreator: %@",
                         promoCode.code, promoCode.properties, promoCode.maxClaimCount, promoCode.claimCount,
                         [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate],
                         promoCode.isEnabled ? @"true" : @"false", promoCode.isClaimable ? @"true" : @"false", promoCode.creator.displayName];
}

#pragma mark - Localization

- (BOOL)changeLanguage:(NSString *)language
{
    [GetSocial setLanguage:language];
    self.languageMenu.detail = [NSString stringWithFormat:@"Current language: %@", [GetSocialLanguageCodes all][language]];
    GSLogInfo(NO, NO, @"Language changed to: %@.", language);
    return YES;
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    if (picker == self.avatarImagePicker)
    {
        [self.avatarImagePicker dismissViewControllerAnimated:YES completion:nil];
        self.avatarImagePicker = nil;

        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        image = [image imageByResizeAndKeepRatio:CGSizeMake(MAX_WIDTH, MAX_HEIGHT)];

        [self showActivityIndicatorView];
        GetSocialUserUpdate* update = [GetSocialUserUpdate new];
        [update setAvatar: image];
        [GetSocial.currentUser updateDetailsWith: update
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
    if ([GetSocialAnalytics trackCustomEvent:eventName properties:properties])
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

