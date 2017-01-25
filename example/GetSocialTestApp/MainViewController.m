/*
 *    	Copyright 2015-2016 GetSocial B.V.
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

#import "AppDelegate.h"
#import "ConsoleViewController.h"
#import "Constants.h"
#import "MainNavigationController.h"
#import "MainViewController.h"
#import "MenuItem.h"
#import "UIBAlertView.h"
#import "UserIdentityUtils.h"
#import "UsersListTableViewController.h"
#import "GetSocialKakaoTalkInvitePlugin.h"

#import <GetSocial/GetSocial.h>
#import <GetSocialChat/GetSocialChat.h>

#import "GetSocialFBMessengerInvitePlugin.h"
#import "GetSocialFacebookInvitePlugin.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>


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

NSString *const kCustomProvider = @"custom";

@interface MainViewController ()

@property(nonatomic, strong) ConsoleViewController *consoleViewController;
@property(nonatomic, strong) ParentMenuItem *uiCustomizationMenu;
@property(nonatomic, strong) ParentMenuItem *chatMenu;
@property(nonatomic, strong) ParentMenuItem *languageMenu;
@property(nonatomic, strong) MenuItem *notificationCenterMenu;
@property(nonatomic, strong) void (^onUnreadPublicRoomsCountChangeHandler)(NSInteger unreadConversationsCount);
@property(nonatomic, strong) void (^onUnreadPrivateRoomsCountChangeHandler)(NSInteger unreadConversationsCount);

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateVersionInfo];

    [self log:LogLevelInfo context:nil message:self.versionLabel.text showAlert:NO showConsole:NO];

    [[GetSocial sharedInstance] setOnReferralDataReceivedHandler:^(NSArray *referralData) {
        GSLogInfo(YES, NO, @"Referral data received: %@.", referralData);
    }];

    [[GetSocial sharedInstance] setOnNotificationsChangeHandler:^(NSInteger unreadNotificationsCount) {
        [self updateUnreadNotificationsCount];
        GSLogInfo(NO, NO, @"Unread Notification count changed to %zd.", unreadNotificationsCount);
    }];

    __weak MainViewController *weakSelf = self;

    [[GetSocial sharedInstance] setInviteFriendsBlock:^(GetSocialInviteFriendsStatus status, NSInteger count) {
        GSLogInfo(NO, NO, @"Invite status: %zd (%zd).", status, count);
    }];

    self.onUnreadPublicRoomsCountChangeHandler = ^(NSInteger unreadPublicRoomsCount) {
        [weakSelf updateUnreadConversationsCount];

        [weakSelf log:LogLevelInfo
                context:@"onUnreadPublicRoomsCountChangeHandler"
                message:[NSString stringWithFormat:@"Chat unread public conversation count changed to %zd,", unreadPublicRoomsCount]
              showAlert:NO
            showConsole:NO];
    };

    self.onUnreadPrivateRoomsCountChangeHandler = ^(NSInteger unreadPrivateRoomsCount) {
        [weakSelf updateUnreadConversationsCount];
        [weakSelf log:LogLevelInfo
                context:@"onUnreadPublicRoomsCountChangeHandler"
                message:[NSString stringWithFormat:@"Chat unread private conversation count changed to %zd,", unreadPrivateRoomsCount]
              showAlert:NO
            showConsole:NO];
    };

    [[GetSocialChat sharedInstance] addOnUnreadRoomsCountChangeHandler:self.onUnreadPublicRoomsCountChangeHandler
                                onUnreadPrivateRoomsCountChangeHandler:self.onUnreadPrivateRoomsCountChangeHandler];

    // Register FBInvitePlugin
    GetSocialFacebookInvitePlugin *fbInvitePlugin = [[GetSocialFacebookInvitePlugin alloc] init];
    [[GetSocial sharedInstance] registerPlugin:fbInvitePlugin provider:kGetSocialProviderFacebook];

    // Register FB Messenger Invite Plugin
    GetSocialFBMessengerInvitePlugin *fbMessengerPlugin = [[GetSocialFBMessengerInvitePlugin alloc] init];
    [[GetSocial sharedInstance] registerPlugin:fbMessengerPlugin provider:kGetSocialProviderFacebookMessenger];
    
    //Register KakaoTalk Invite Plugin
    GetSocialKakaoTalkInvitePlugin *kakaoPlugin = [[GetSocialKakaoTalkInvitePlugin alloc] init];
    [[GetSocial sharedInstance] registerPlugin:kakaoPlugin provider:kGetSocialProviderKakao];

    [self allowAnonymousUsersToInteract:NO];
}

- (void)updateUnreadConversationsCount
{
    self.chatMenu.detail =
        [NSString stringWithFormat:@"Unread conversations: Public (%zd) - Private (%zd)", [GetSocialChat sharedInstance].unreadPublicRoomsCount,
                                   [GetSocialChat sharedInstance].unreadPrivateRoomsCount];
}

- (void)updateUnreadNotificationsCount
{
    self.notificationCenterMenu.detail =
        [NSString stringWithFormat:@"Unread notifications: %zd", [GetSocial sharedInstance].unreadNotificationsCount];
}

- (void)awakeFromNib
{
    [self loadMenu];
}

- (void)updateVersionInfo
{
    self.versionLabel.text = [NSString stringWithFormat:@"GetSocial iOS Test App\nSDK v%@ - API v%@", [GetSocial sharedInstance].sdkVersion, [GetSocial sharedInstance].apiVersion];
}

- (void)loadMenu
{
    [[GetSocial sharedInstance] usersWithProvider:nil userIds:nil success:nil failure:nil];

    if (!self.menu)
    {
        self.menu = [NSMutableArray array];

        // User Management Menu
        ParentMenuItem *userAuthenticationMenu = [MenuItem parentMenuItemWithTitle:@"User Management"];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Change user display name"
                                                                          action:^{
                                                                              [self changeUserDisplayName];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Change user avatar"
                                                                          action:^{
                                                                              [self changeUserAvatar];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Add Facebook user identity"
                                                                          action:^{
                                                                              [self addFBUserIdentityWithSuccess:nil failure:nil];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Add Custom user identity"
                                                                          action:^{
                                                                              [self addCustomUserIdentityWithSuccess:nil failure:nil];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Remove Facebook user identity"
                                                                          action:^{
                                                                              [self removeFBUserIdentity];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Remove Custom user identity"
                                                                          action:^{
                                                                              [self removeCustomUserIdentity];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Reset current user"
                                                                          action:^{
                                                                              [self resetUser];
                                                                          }]];

        [self.menu addObject:userAuthenticationMenu];

        // Activities Menu
        ParentMenuItem *activitiesMenu = [MenuItem parentMenuItemWithTitle:@"Activities"];

        [activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open Global Activities"
                                                                  action:^{
                                                                      [self openGlobalActivities];
                                                                  }]];

        [activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open Activities Filtered by Group"
                                                                  action:^{
                                                                      [self openActivitiesFilteredByGroup];
                                                                  }]];

        // Post Activities
        ParentMenuItem *postActivitiesMenu = [MenuItem parentMenuItemWithTitle:@"Post Activity"];

        [postActivitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Text"
                                                      action:^{
                                                          [self postActivity:@"Text" withImage:nil buttonText:nil action:nil andTags:nil];
                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Image"
                                                                      action:^{
                                                                          [self postActivity:nil
                                                                                   withImage:[UIImage imageNamed:@"activityImage.png"]
                                                                                  buttonText:nil
                                                                                      action:nil
                                                                                     andTags:nil];
                                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Text + Image"
                                                                      action:^{
                                                                          [self postActivity:@"Text+Image"
                                                                                   withImage:[UIImage imageNamed:@"activityImage.png"]
                                                                                  buttonText:nil
                                                                                      action:nil
                                                                                     andTags:nil];
                                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Text + Button"
                                                                      action:^{
                                                                          [self postActivity:@"Text+Button"
                                                                                   withImage:nil
                                                                                  buttonText:@"Click here"
                                                                                      action:@"action"
                                                                                     andTags:nil];
                                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Text + Image + Button"
                                                                      action:^{
                                                                          [self postActivity:@"Text+Image+Button"
                                                                                   withImage:[UIImage imageNamed:@"activityImageWithAction.png"]
                                                                                  buttonText:@"Click here"
                                                                                      action:@"action"
                                                                                     andTags:nil];
                                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Image + Button"
                                                                      action:^{
                                                                          [self postActivity:nil
                                                                                   withImage:[UIImage imageNamed:@"activityImageWithAction.png"]
                                                                                  buttonText:@"Click here"
                                                                                      action:@"action"
                                                                                     andTags:nil];
                                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Image + Action"
                                                                      action:^{
                                                                          [self postActivity:nil
                                                                                   withImage:[UIImage imageNamed:@"activityImageWithButton.png"]
                                                                                  buttonText:nil
                                                                                      action:@"action"
                                                                                     andTags:nil];
                                                                      }]];

        [activitiesMenu addSubmenu:postActivitiesMenu];

        [self.menu addObject:activitiesMenu];

        // Smart Invites Menu
        ParentMenuItem *smartInvitesMenu = [MenuItem parentMenuItemWithTitle:@"Smart Invites"];

        [smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open Smart Invites UI"
                                                                    action:^{
                                                                        [self openSmartInvites];
                                                                    }]];

        [smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Send Customized Smart Invite"
                                                                    action:^{
                                                                        [self openCustomizedSmartInvite];
                                                                    }]];

        [smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Invite without UI"
                                                                    action:^{
                                                                        [self inviteWithoutUI];
                                                                    }]];

        [self.menu addObject:smartInvitesMenu];

        // Chat Menu
        self.chatMenu = [MenuItem parentMenuItemWithTitle:@"Chat"];

        [self.chatMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open Global Chat"
                                                                 action:^{
                                                                     [self openGlobalChat];
                                                                 }]];

        [self.chatMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open Conversation List"
                                                                 action:^{
                                                                     [self openChatList];
                                                                 }]];

        [self.menu addObject:self.chatMenu];
        [self updateUnreadConversationsCount];

        // Notification Center Menu
        self.notificationCenterMenu = [MenuItem actionableMenuItemWithTitle:@"Notification Center"
                                                                     action:^{
                                                                         [self openNotificationCenter];
                                                                     }];
        
        
        [self.menu addObject:self.notificationCenterMenu];
        [self updateUnreadNotificationsCount];

        // UI Customization Menu
        self.uiCustomizationMenu = [MenuItem parentMenuItemWithTitle:@"UI Customization"];
        self.uiCustomizationMenu.detail = @"Current UI: Default";

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Default UI"
                                                                               isChecked:YES
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadDefaultUI];
                                                                                  }]];

        MenuItem *customUrlUIMenu = [MenuItem groupedCheckableMenuItemWithTitle:@"Custom UI from Url"
                                                                      isChecked:NO
                                                                         action:^BOOL(BOOL isChecked) {
                                                                             return [self loadCustomUrlUI];
                                                                         }];

        customUrlUIMenu.name = @"customUrlUI";

        [self.uiCustomizationMenu addSubmenu:customUrlUIMenu];

        [self.menu addObject:self.uiCustomizationMenu];

        // Leaderboards Menu
        ParentMenuItem *leaderboardsMenu = [MenuItem parentMenuItemWithTitle:@"Leaderboards"];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get User Rank on Leaderboard 1"
                                                                    action:^{
                                                                        [self getLeaderboard1];
                                                                    }]];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get User Rank on Leaderboards 1, 2 and 3"
                                                                    action:^{
                                                                        [self getLeaderboard123];
                                                                    }]];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get first 5 Leaderboards"
                                                                    action:^{
                                                                        [self getFirst5Leaderboards];
                                                                    }]];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get first 5 scores from Leaderboard 1 (world)"
                                                                    action:^{
                                                                        [self getFirst5ScoresFromLeaderboard1];
                                                                    }]];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get first 5 scores from Leaderboard 1 (following)"
                                                                    action:^{
                                                                        [self getFirst5ScoresFromfollowingFromLeaderboard1];
                                                                    }]];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Submit score to Leaderboard 1"
                                                                    action:^{
                                                                        [self submitScoreToLeaderboard:@"leaderboard_one" withTitle:@"Leaderboard 1"];
                                                                    }]];

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Submit score to Leaderboard 2"
                                                                    action:^{
                                                                        [self submitScoreToLeaderboard:@"leaderboard_two" withTitle:@"Leaderboard 2"];
                                                                    }]];

        [self.menu addObject:leaderboardsMenu];

        // Cloud Save Menu
        ParentMenuItem *cloudSaveMenu = [MenuItem parentMenuItemWithTitle:@"Cloud Save"];

        [cloudSaveMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Save state"
                                                                 action:^{
                                                                     [self saveState];
                                                                 }]];
        [cloudSaveMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get saved state"
                                                                 action:^{
                                                                     [self getSavedState];
                                                                 }]];

        [self.menu addObject:cloudSaveMenu];
        
        // Following/Followers Save Menu
        ParentMenuItem *followingFollowers = [MenuItem parentMenuItemWithTitle:@"Following/Followers"];
        
        [followingFollowers addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Following List"
                                                                      action:^{
                                                                          [self openFollowingList];
                                                                      }]];
        
        [followingFollowers addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Followers List"
                                                                      action:^{
                                                                          [self openFollowersList];
                                                                      }]];

        [self.menu addObject:followingFollowers];

        // Settings Menu
        ParentMenuItem *settingsMenu = [MenuItem parentMenuItemWithTitle:@"Settings"];

        self.languageMenu = [MenuItem parentMenuItemWithTitle:@"Change Language"];

        if ([GetSocial sharedInstance].isInitialized)
        {
            [self updateLanguage];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] addObserverForName:GetSocialWasInitializedNotification
                                                              object:nil
                                                               queue:nil
                                                          usingBlock:^(NSNotification *_Nonnull note) {
                                                              [self updateLanguage];
                                                          }];
        }

        NSArray *sortedLanguages = [[[self languages] allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[self languages][obj1] localizedCaseInsensitiveCompare:[self languages][obj2]];
        }];

        for (NSString *key in sortedLanguages)
        {
            [self.languageMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:[self languages][key]
                                                                            isChecked:NO
                                                                               action:^BOOL(BOOL isChecked) {
                                                                                   return [self changeLanguage:key];
                                                                               }]];
        }

        [settingsMenu addSubmenu:self.languageMenu];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Allow anonymous users to interact"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self allowAnonymousUsersToInteract:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"User generated content handler"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableUserGeneratedContentHandler:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"User avatar click custom behaviour"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableUserAvatarClickCustomBehaviour:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Custom app avatar click behaviour"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableAppAvatarClickCustomBehaviour:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Custom invite button click behaviour"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableInviteButtonClickCustomBehaviour:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Activity action click custom behaviour"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableActivityClickCustomBehaviour:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Window state custom behaviour"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableWindowStateCustomBehaviour:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Register for Push Notifications"
                                                                action:^{
                                                                    [self registerForPushNotifications];
                                                                }]];

        [self.menu addObject:settingsMenu];
    }
}

#pragma mark - Authentication

- (void)changeUserDisplayName
{
    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:@"User Display Name"
                                                      message:@"Enter the new Display Name"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert textFieldAtIndex:0].text = [UserIdentityUtils randomDisplayName];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            NSString *displayName = [alert textFieldAtIndex:0].text;

            [[GetSocial sharedInstance]
                    .currentUser setDisplayName:displayName
                success:^{
                    GSLogInfo(YES, NO, @"User display name was changed to %@", displayName);
                    [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
                }
                failure:^(NSError *error) {
                    GSLogError(YES, NO, @"Cannot change user display name to %@. Reason %@", displayName, [error localizedDescription]);
                }];
        }
    }];
}

- (void)changeUserAvatar
{
    NSString *avatarUrl = [UserIdentityUtils randomAvatarUrl];

    [[GetSocial sharedInstance]
            .currentUser setAvatarUrl:avatarUrl
        success:^{
            GSLogInfo(YES, NO, @"User avatar was changed to %@", avatarUrl);
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Cannot change avatar to %@. Reason %@", avatarUrl, [error localizedDescription]);
        }];
}

- (void)loginWithFacebookWithToken:(NSString *)token userId:(NSString *)userId success:(void (^)())success failure:(void (^)(NSError *))failure
{
    GetSocialUserIdentity *identity = [GetSocialUserIdentity identityWithProvider:kGetSocialProviderFacebook token:token];
    GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;
    [currentUser addUserIdentity:identity
        complete:^(GetSocialAddIdentityResult result) {
            GSLogInfo(NO, NO, @"App FB Auth -> GetSocial Add FB User Identity result: %@", [self userIdentityResultString:result]);
            if (success)
            {
                success();
            }
        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"App FB Auth -> GetSocial Add FB User Identity failed: %@.", [error localizedDescription]);
            if (failure)
            {
                failure(error);
            }
        }
        conflict:nil];
}

- (void)loginWithFacebookWithHandler:(FBSDKLoginManagerRequestTokenHandler)handler
{
    [[FBSDKLoginManager new] logInWithReadPermissions:kGetSocialAuthPermissionsFacebook fromViewController:self handler:handler];
}

- (void)addFBUserIdentityWithSuccess:(void (^)())success failure:(void (^)())failure
{
    GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;

    if (![currentUser userIdForProvider:kGetSocialProviderFacebook])
    {
        [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {

            if (!error && !result.isCancelled)
            {
                GetSocialUserIdentity *identity = [GetSocialUserIdentity facebookIdentityWithToken:result.token.tokenString];

                [currentUser addUserIdentity:identity
                    complete:^(GetSocialAddIdentityResult result) {
                        GSLogInfo(YES, NO, @"App FB Auth -> GetSocial Add FB User Identity result: %@", [self userIdentityResultString:result]);

                        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];

                        if (success)
                        {
                            success();
                        }

                    }
                    failure:^(NSError *error) {
                        GSLogError(YES, NO, @"App FB Auth -> GetSocial Add FB User Identity failed: %@.", [error localizedDescription]);

                        if (failure)
                        {
                            failure();
                        }

                    }
                    conflict:^(GetSocialUser *currentUser, GetSocialUser *remoteUser,
                               void (^resolve)(GetSocialAddIdentityConflictResolutionStrategy strategy)) {

                        [self showAlertViewToResolveIdentityConflictWithCurrentUser:currentUser
                                                                         remoteUser:remoteUser
                                                                            resolve:^(GetSocialAddIdentityConflictResolutionStrategy strategy) {

                                                                                if (strategy == GetSocialAddIdentityResultConflictResolvedWithCurrent)
                                                                                {
                                                                                    FBSDKLoginManager *loginManager = [FBSDKLoginManager new];
                                                                                    [loginManager logOut];
                                                                                }

                                                                                resolve(strategy);
                                                                            }];

                    }];
            }
            else
            {
                if (failure)
                {
                    failure();
                }
            }

        }];
    }
    else
    {
        GSLogInfo(YES, NO, @"User has already a Facebook identity.");
    }
}

- (void)removeFBUserIdentity
{
    [[FBSDKLoginManager new] logOut];

    GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;
    if ([currentUser userIdForProvider:kGetSocialProviderFacebook])
    {
        [currentUser removeUserIdentityForProvider:kGetSocialProviderFacebook
            success:^{

                GSLogInfo(YES, NO, @"UserIdentity removed for Provider %@.", kGetSocialProviderFacebook);
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            }
            failure:^(NSError *error) {
                GSLogError(YES, NO, @"Failed to remove UserIdentity for Provider %@, error: %@", kGetSocialProviderFacebook,
                           [error localizedDescription]);
            }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User doesn't have UserIdentity for Provider %@.", kGetSocialProviderFacebook);
    }
}

- (void)addCustomUserIdentityWithSuccess:(void (^)())success failure:(void (^)())failure
{
    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:@"Add Custom User identity"
                                                      message:@"Enter UserId and Token"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;

    [alert textFieldAtIndex:0].placeholder = @"UserId";
    [alert textFieldAtIndex:1].placeholder = @"Token";

    [[alert textFieldAtIndex:1] setSecureTextEntry:NO];
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            NSString *userId = [alert textFieldAtIndex:0].text;
            NSString *token = [alert textFieldAtIndex:1].text;

            if (![userId isEqualToString:@""] && ![token isEqualToString:@""])
            {
                GetSocialUserIdentity *identity = [GetSocialUserIdentity identityWithProvider:kCustomProvider userId:userId token:token];

                GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;
                [currentUser addUserIdentity:identity
                    complete:^(GetSocialAddIdentityResult result) {
                        GSLogInfo(YES, NO, @"User identity added %@ for Provider '%@', result: %@", userId, kCustomProvider,
                                  [self userIdentityResultString:result]);
                        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];

                        if (success)
                        {
                            success();
                        }

                    }
                    failure:^(NSError *error) {
                        GSLogError(YES, NO, @"Failed to add user identity %@ for Provider '%@', error: %@", userId, kCustomProvider,
                                   [error localizedDescription]);

                        if (failure)
                        {
                            failure();
                        }
                    }
                    conflict:^(GetSocialUser *currentUser, GetSocialUser *remoteUser,
                               void (^resolve)(GetSocialAddIdentityConflictResolutionStrategy strategy)) {

                        [self showAlertViewToResolveIdentityConflictWithCurrentUser:currentUser
                                                                         remoteUser:remoteUser
                                                                            resolve:^(GetSocialAddIdentityConflictResolutionStrategy strategy) {
                                                                                resolve(strategy);
                                                                            }];

                    }];
            }
        }
        else
        {
            if (failure)
            {
                failure();
            }
        }
    }];
}

- (void)removeCustomUserIdentity
{
    GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;
    if ([currentUser userIdForProvider:kCustomProvider])
    {
        [currentUser removeUserIdentityForProvider:kCustomProvider
            success:^{
                GSLogInfo(YES, NO, @"User identity removed for Provider '%@'", kCustomProvider);
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            }
            failure:^(NSError *error) {
                GSLogError(YES, NO, @"Failed to remove user identity for Provider '%@', error: %@", kCustomProvider, [error localizedDescription]);
            }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User doesn't have user identity for Provider '%@'", kCustomProvider);
    }
}

- (void)resetUser
{
    [[GetSocial sharedInstance]
            .currentUser resetWithSuccess:^{
        GSLogWarning(YES, NO, @"User was reset.", nil);

        // log out from FB
        [[FBSDKLoginManager new] logOut];

        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
    }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Couldn't reset user. Reason %@", [error localizedDescription]);
        }];
}

- (void)showAlertViewToResolveIdentityConflictWithCurrentUser:(GetSocialUser *)currentUser
                                                   remoteUser:(GetSocialUser *)remoteUser
                                                      resolve:(void (^)(GetSocialAddIdentityConflictResolutionStrategy strategy))resolve
{
    UIBAlertView *alert =
        [[UIBAlertView alloc] initWithTitle:@"Conflict"
                                    message:@"The new identity is already linked to another user. Which one do you want to continue using?"
                          cancelButtonTitle:[NSString stringWithFormat:@"%@ (Current)", currentUser.displayName]
                          otherButtonTitles:@[ [NSString stringWithFormat:@"%@ (Remote)", remoteUser.displayName] ]];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (resolve)
        {
            if (didCancel)
            {
                resolve(GetSocialAddIdentityConflictResolutionStrategyCurrent);
                GSLogInfo(NO, NO, @"Identity conflict was resolve with current user");
            }
            else
            {
                resolve(GetSocialAddIdentityConflictResolutionStrategyRemote);
                GSLogInfo(NO, NO, @"Identity conflict was resolve with remote user");
            }
        }
    }];
}

#pragma mark - Activities

- (void)openGlobalActivities
{
    GetSocialActivitiesViewBuilder *viewBuilder = [[GetSocial sharedInstance] createActivitiesView];
    [viewBuilder show];
}

- (void)openActivitiesFilteredByGroup
{
    GetSocialActivitiesViewBuilder *viewBuilder = [[GetSocial sharedInstance] createActivitiesViewWithGroup:@"world1" andTag:@"swamp"];
    [viewBuilder show];
}

- (void)postActivity:(NSString *)activityText
           withImage:(UIImage *)image
          buttonText:(NSString *)buttonText
              action:(NSString *)action
             andTags:(NSArray *)tags
{
    [[GetSocial sharedInstance] postActivity:activityText
        withImage:image
        buttonText:buttonText
        action:action
        andTags:tags
        success:^{
            [self openGlobalActivities];
        }
        failure:^(NSError *error) {
            GSLogWarning(YES, NO, @"User is not logged in.", nil);
        }];
}

#pragma mark - Notification Center

- (void)openNotificationCenter
{
    GetSocialNotificationsViewBuilder *viewBuilder = [[GetSocial sharedInstance] createNotificationsView];
    [viewBuilder show];
}

- (void)openNotificationCenterWithoutConversationList
{
    GetSocialNotificationsViewBuilder *viewBuilder = [[GetSocial sharedInstance] createNotificationsView];
    [viewBuilder show];
}

- (void)registerForPushNotifications
{
    [[GetSocial sharedInstance] registerForPushNotifications];
}

#pragma mark - Smart Invites

- (void)openSmartInvites
{
    GetSocialSmartInviteViewBuilder *viewBuilder = [[GetSocial sharedInstance] createSmartInviteView];
    [viewBuilder show];
}

- (void)openCustomizedSmartInvite
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CustomSmartInvite"];
    [self.mainNavigationController pushViewController:vc animated:YES];
}

- (void)requestProviderUserIdWithTitle:(NSString *)title dismissHandler:(void (^)(NSString *provider, NSString *userId, BOOL didCancel))handler
{
    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:title
                                                      message:@"Enter Provider and UserId of the user to check"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;

    [alert textFieldAtIndex:0].placeholder = @"Provider";
    [alert textFieldAtIndex:0].text = kGetSocialProviderFacebook;
    [alert textFieldAtIndex:1].placeholder = @"UserId";
    [[alert textFieldAtIndex:1] setSecureTextEntry:NO];
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        NSString *provider = [alert textFieldAtIndex:0].text;
        NSString *userId = [alert textFieldAtIndex:1].text;

        if (handler)
        {
            handler(provider, userId, didCancel);
        }
    }];
}

- (void)inviteWithoutUI
{
    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:@"Smart Invite"
                                                      message:@"Choose provider"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:[[GetSocial sharedInstance] getSupportedInviteProviders]];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            [[GetSocial sharedInstance] inviteFriendsUsingProvider:selectedTitle withProperties:nil];
        }
    }];
}

#pragma mark - Following

- (void)openFollowingList
{
    GetSocialUserListViewBuilder *viewBuilder =
    [[GetSocial sharedInstance] createUserListViewWithType:GetSocialUserListFollowingType dismissHandler:^(GetSocialUser *user, BOOL didCancel) {
            if (!didCancel)
            {
                [self showAlertFriendClick:user];
            }
            else
            {
                GSLogInfo(YES, NO, @"User list closed", nil);
            }
        }];
    viewBuilder.title = @"Friends";
    [viewBuilder show];
}

- (void)openFollowersList
{
    GetSocialUserListViewBuilder *viewBuilder =
    [[GetSocial sharedInstance] createUserListViewWithType:GetSocialUserListFollowersType dismissHandler:^(GetSocialUser *user, BOOL didCancel) {
        if (!didCancel)
        {
            GSLogInfo(YES, NO, @"User %@ (%@) was clicked.", user.displayName, user.guid);
        }
        else
        {
            GSLogInfo(YES, NO, @"Followers list closed", nil);
        }
    }];
    viewBuilder.title = @"Followers";
    viewBuilder.showInviteButton = NO;
    [viewBuilder show];
}


#pragma mark - Chat

- (void)openGlobalChat
{
    GetSocialChatViewBuilder *viewBuilder = [[GetSocialChat sharedInstance] createChatViewForRoomName:@"global"];
    viewBuilder.title = @"Global Chat";
    [viewBuilder show];
}

- (void)openChatList
{
    GetSocialChatListViewBuilder *viewBuilder = [[GetSocialChat sharedInstance] createChatListView];
    [viewBuilder show];
}

#pragma mark - Leaderboards

- (void)getLeaderboard1
{
    [[GetSocial sharedInstance] leaderboard:@"leaderboard_one"
        success:^(GetSocialLeaderboard *leaderboard) {

            if (leaderboard)
            {
                [self logLeaderboards:@[ leaderboard ]];
            }
            else
            {
                GSLogError(YES, NO, @"Cannot get Leaderboard 1", nil);
            }

        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Cannot get Leaderboard 1", nil);
        }];
}

- (void)getLeaderboard123
{
    [[GetSocial sharedInstance] leaderboards:[NSArray arrayWithObjects:@"leaderboard_one", @"leaderboard_two", @"leaderboard_three", nil]
        success:^(NSArray *leaderboards) {
            [self logLeaderboards:leaderboards];
        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Cannot get Leaderboard List. Reason %@", [error localizedDescription]);
        }];
}

- (void)getFirst5Leaderboards
{
    [[GetSocial sharedInstance] leaderboards:0
        count:5
        success:^(NSArray *leaderboards) {
            [self logLeaderboards:leaderboards];
        }
        failure:^(NSError *error) {
            GSLogError(YES, NO, @"Cannot get Leaderboard List. Reason %@", [error localizedDescription]);
        }];
}

- (void)logLeaderboards:(NSArray *)leaderboards
{
    if (leaderboards.count > 0)
    {
        NSMutableString *responseString = [NSMutableString string];
        for (GetSocialLeaderboard *leaderboard in leaderboards)
        {
            if (leaderboard.currentScore)
            {
                [responseString appendFormat:@"You are ranked %zd in %@ with %zd %@.\n", (long)leaderboard.currentScore.rank,
                                             leaderboard.leaderboardMetaData.name, (long)leaderboard.currentScore.value,
                                             leaderboard.leaderboardMetaData.unit];
            }
            else
            {
                [responseString appendFormat:@"You have no %@ on %@.\n", leaderboard.leaderboardMetaData.unit, leaderboard.leaderboardMetaData.name];
            }
        }

        GSLogInfo(NO, YES, responseString, nil);
    }
    else
    {
        GSLogInfo(YES, NO, @"Leaderboards were not found.", nil);
    }
}

- (void)getFirst5ScoresFromLeaderboard1
{
    [[GetSocial sharedInstance] leaderboardScores:@"leaderboard_one"
        offset:0
        count:5
        scoreType:GetSocialLeaderboardScoreTypeWorld
        success:^(NSArray *scores) {

            if (scores.count > 0)
            {
                NSMutableString *responseString = [NSMutableString string];

                for (GetSocialLeaderboardScore *score in scores)
                {
                    [responseString appendFormat:@"#%zd %@: %zd.\n", score.rank, score.user.displayName, score.value];
                }

                GSLogInfo(NO, YES, responseString, nil);
            }
            else
            {
                GSLogInfo(YES, NO, @"There are no scores on Leaderboard 1.", nil);
            }

        }
        failure:^(NSError *error) {

            GSLogError(YES, NO, @"Cannot get scores. Reason %@", [error localizedDescription]);

        }];
}

- (void)getFirst5ScoresFromfollowingFromLeaderboard1
{
    [[GetSocial sharedInstance] leaderboardScores:@"leaderboard_one"
        offset:0
        count:5
        scoreType:GetSocialLeaderboardScoreTypeFollowing
        success:^(NSArray *scores) {

            if (scores.count > 0)
            {
                NSMutableString *responseString = [NSMutableString string];

                for (GetSocialLeaderboardScore *score in scores)
                {
                    [responseString appendFormat:@"#%zd %@: %zd.\n", score.rank, score.user.displayName, score.value];
                }

                GSLogInfo(NO, YES, responseString, nil);
            }
            else
            {
                GSLogInfo(YES, NO, @"There are no scores on Leaderboard 1.", nil);
            }

        }
        failure:^(NSError *error) {

            GSLogError(YES, NO, @"Cannot get scores. Reason %@", [error localizedDescription]);

        }];
}

- (void)submitScoreToLeaderboard:(NSString *)leaderboardId withTitle:(NSString *)leaderboardTitle
{
    NSInteger rndValue = 1 + arc4random() % (1000 - 1);  // generate random number between 1 and 1000

    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:leaderboardTitle
                                                      message:@"Enter score to submit"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"%zd", rndValue];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            NSString *score = [alert textFieldAtIndex:0].text;

            [[GetSocial sharedInstance] submitLeaderboardScore:[score integerValue]
                forLeaderboardId:leaderboardId
                success:^(NSInteger position) {

                    GSLogInfo(YES, NO, @"Score %zd submitted on %@. Now on rank %zd", rndValue, leaderboardId, position);

                }
                failure:^(NSError *error) {

                    GSLogError(YES, NO, @"Cannot submit scores. Reason %@", [error localizedDescription]);

                }];
        }
    }];
}

#pragma mark - Localization

- (BOOL)changeLanguage:(NSString *)language
{
    [[GetSocial sharedInstance] setLanguage:language];

    [self updateLanguage];

    GSLogInfo(NO, NO, @"Language changed to: %@.", language);
    return YES;
}

- (void)updateLanguage
{
    NSString *currentLanguage = [GetSocial sharedInstance].language;
    self.languageMenu.detail = [NSString stringWithFormat:@"Current language: %@", [self languages][currentLanguage]];
}

- (NSDictionary *)languages
{
    return @{
        @"da" : @"Danish",
        @"de" : @"German",
        @"en" : @"English",
        @"es" : @"Spanish",
        @"fr" : @"French",
        @"id" : @"Indonesian",
        @"is" : @"Icelandic",
        @"it" : @"Italian",
        @"ja" : @"Japanese",
        @"ko" : @"Korean",
        @"ms" : @"Malay",
        @"nb" : @"Norwegian",
        @"nl" : @"Dutch",
        @"pl" : @"Polish",
        @"pt" : @"Portuguese",
        @"pt-br" : @"Portuguese (Brazil)",
        @"ru" : @"Russian",
        @"sv" : @"Swedish",
        @"tl" : @"Filipino",
        @"tr" : @"Turkish",
        @"uk" : @"Ukrainian",
        @"vi" : @"Vietnamese",
        @"zh-Hans" : @"Chinese Simplified",
        @"zh-Hant" : @"Chinese Traditional",
    };
}

#pragma mark - Custom Handlers

- (BOOL)enableWindowStateCustomBehaviour:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnWindowStateChangedHandler:^(BOOL isOpen) {
            GSLogInfo(YES, NO, @"Window is now %@.", isOpen ? @"open" : @"close");
        }];
        GSLogInfo(NO, NO, @"Window state custom behaviour was set.");
    }
    else
    {
        [[GetSocial sharedInstance] setOnWindowStateChangedHandler:nil];
        GSLogInfo(NO, NO, @"Window state custom behaviour was removed.");
    }
    return YES;
}

- (BOOL)enableActivityClickCustomBehaviour:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnActivityActionClickHandler:^(NSString *action) {
            GSLogInfo(YES, NO, @"Click on activity with action %@.", action);
        }];
        GSLogInfo(NO, NO, @"Activity click custom behaviour was set.");
    }
    else
    {
        [[GetSocial sharedInstance] setOnActivityActionClickHandler:nil];
        GSLogInfo(NO, NO, @"Activity click custom behaviour was removed.");
    }
    return YES;
}

- (BOOL)allowAnonymousUsersToInteract:(BOOL)isChecked
{
    if (!isChecked)
    {
        [[GetSocial sharedInstance] setOnActionPerformHandler:^(GetSocialAction action, void (^finalize)(BOOL shouldPerformAction)) {

            NSString *actionString = [self actionString:action];
            GSLogInfo(NO, NO, @"Performing action: %@.", actionString);

            BOOL allowAnonymousAction = YES;

            switch (action)
            {
                case GetSocialActionLikeActivity:
                case GetSocialActionLikeComment:
                case GetSocialActionPostActivity:
                case GetSocialActionPostComment:
                case GetSocialActionSendPrivateChatMessage:
                case GetSocialActionSendPublicChatMessage:
                    allowAnonymousAction = NO;
                    break;

                default:
                    break;
            }

            if ([GetSocial sharedInstance].currentUser.isAnonymous && !allowAnonymousAction)
            {
                GSLogInfo(NO, NO, @"Requesting to add identity for action: %@.", actionString);

                UIBAlertView *alert =
                    [[UIBAlertView alloc] initWithTitle:@"Anonymous user"
                                                message:[NSString stringWithFormat:@"You need to add an identity to %@", actionString]
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@[ @"Facebook", @"Custom" ]];

                [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

                    if (didCancel)
                    {
                        GSLogInfo(NO, NO, @"Request to add identity for action: %@ was cancelled.", actionString);

                        finalize(NO);
                        return;
                    }

                    switch (selectedIndex)
                    {
                        case 1:
                        {
                            GSLogInfo(NO, NO, @"Adding FB identity to continue with action: %@.", actionString);
                            [[GetSocial sharedInstance] closeView:YES];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                                [self addFBUserIdentityWithSuccess:^{
                                    [[GetSocial sharedInstance] restoreView];
                                    finalize(YES);
                                }
                                                           failure:^{
                                                               [[GetSocial sharedInstance] restoreView];
                                                               finalize(NO);
                                                           }];
                            });

                            break;
                        }
                        case 2:
                        {
                            GSLogInfo(NO, NO, @"Adding Custom identity to continue with action: %@.", actionString);
                            [self addCustomUserIdentityWithSuccess:^{
                                finalize(YES);
                            }
                                failure:^{
                                    finalize(NO);
                                }];

                            break;
                        }
                    }
                }];
            }
            else
            {
                finalize(YES);
            }
        }];

        GSLogInfo(NO, NO, @"Perform action handler was set.");
    }
    else
    {
        [[GetSocial sharedInstance] setOnActionPerformHandler:^(GetSocialAction action, void (^finalize)(BOOL shouldPerformAction)) {
            NSString *actionString = [self actionString:action];

            GSLogInfo(NO, NO, @"Performing action: %@.", actionString);
            finalize(YES);

        }];

        GSLogInfo(NO, NO, @"Perform action handler was removed.");
    }
    return YES;
}

- (BOOL)enableUserGeneratedContentHandler:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnUserGeneratedContentHandler:^NSString *(GetSocialContentSource source, NSString *content) {

            GSLogInfo(NO, NO, @"User Content (%@) was generated \"%@\".", [self sourceString:source], content);

            return [NSString stringWithFormat:@"%@ (verified 👮)", content];
        }];

        GSLogInfo(NO, NO, @"User generated content handler was set.");
    }
    else
    {
        [[GetSocial sharedInstance] setOnUserGeneratedContentHandler:nil];
        GSLogInfo(NO, NO, @"User generated content handler was removed.");
    }
    return YES;
}

- (BOOL)enableUserAvatarClickCustomBehaviour:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnUserAvatarClickHandler:^BOOL(GetSocialUser *user, GetSocialSourceView source) {
            
            [self showAlertAvatarClick:user];
            return YES;
        }];
    }
    else
    {
        [[GetSocial sharedInstance] setOnUserAvatarClickHandler:nil];
        GSLogInfo(NO, NO, @"User avatar click custom behaviour was removed.");
    }
    return YES;
}

- (BOOL)enableAppAvatarClickCustomBehaviour:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnAppAvatarClickHandler:^BOOL {
            GSLogInfo(YES, NO, @"Click on app avatar.", nil);
            return YES;
        }];
        GSLogInfo(NO, NO, @"App avatar click custom behaviour was set.");
    }
    else
    {
        [[GetSocial sharedInstance] setOnAppAvatarClickHandler:nil];
        GSLogInfo(NO, NO, @"App avatar click custom behaviour was removed.");
    }
    return YES;
}

- (BOOL)enableInviteButtonClickCustomBehaviour:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnInviteButtonClickHandler:^BOOL {
            GSLogInfo(YES, NO, @"Click on invite button.", nil);
            return YES;
        }];
        GSLogInfo(NO, NO, @"Invite button click custom behaviour was set.");
    }
    else
    {
        [[GetSocial sharedInstance] setOnInviteButtonClickHandler:nil];
        GSLogInfo(NO, NO, @"Invite button click custom behaviour was removed.");
    }
    return YES;
}

- (NSString *)actionString:(GetSocialAction)action
{
    switch (action)
    {
        case GetSocialActionOpenActivities:
            return @"Open Activities";
            break;
        case GetSocialActionOpenActivityDetails:
            return @"Open Activity";
            break;
        case GetSocialActionPostActivity:
            return @"Post Activity";
            break;
        case GetSocialActionPostComment:
            return @"Post Comment";
            break;
        case GetSocialActionLikeActivity:
            return @"Like Activity";
            break;
        case GetSocialActionLikeComment:
            return @"Like Comment";
            break;
        case GetSocialActionOpenFriendsList:
            return @"Open Friends List";
            break;
        case GetSocialActionOpenSmartInvites:
            return @"Open Smart Invites";
            break;
        case GetSocialActionOpenNotifications:
            return @"Open Notifications";
            break;
        case GetSocialActionOpenChatList:
            return @"Open Chat List";
            break;
        case GetSocialActionOpenPrivateChat:
            return @"Open Private Chat";
            break;
        case GetSocialActionOpenPublicChat:
            return @"Open Public Chat";
            break;
        case GetSocialActionSendPrivateChatMessage:
            return @"Send Private Chat Message";
            break;
        case GetSocialActionSendPublicChatMessage:
            return @"Send Public Chat Message";
            break;
        default:
            return @"";
            break;
    }
}

- (NSString *)sourceString:(GetSocialContentSource)source
{
    switch (source)
    {
        case GetSocialContentSourceActivity:
            return @"Activity";
            break;
        case GetSocialContentSourceComment:
            return @"Comment";
            break;
        case GetSocialContentSourcePrivateChatMessage:
            return @"Private Chat Message";
            break;
        case GetSocialContentSourcePublicChatMessage:
            return @"Public Chat Message";
            break;
        default:
            return @"";
            break;
    }
}

- (NSString *)userIdentityResultString:(GetSocialAddIdentityResult)result
{
    switch (result)
    {
        case GetSocialAddIdentityResultIdentityAdded:
            return @"Identity Added";
            break;

        case GetSocialAddIdentityResultConflictResolvedWithCurrent:
            return @"Conflict Resolved with Current";
            break;

        case GetSocialAddIdentityResultConflictResolvedWithRemote:
            return @"Conflict Resolved with Remote";
            break;

        default:
            return @"";
            break;
    }
}

#pragma mark - UI Customization

- (BOOL)loadDefaultUI
{
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];

    [[GetSocial sharedInstance].configuration clear];

    self.uiCustomizationMenu.detail = @"Current UI: Default";
    return YES;
}

- (BOOL)loadCustomUrlUI
{
    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:@"Change UI Configuration"
                                                      message:@"Enter URL for JSON Config"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    NSString *savedCustomUrlUI = [[NSUserDefaults standardUserDefaults] objectForKey:@"GetSocialUIConfigurationCustomURL"];

    if (!savedCustomUrlUI)
    {
        savedCustomUrlUI = @"https://downloads.getsocial.im/all/default.json";
    }

    [alert textFieldAtIndex:0].text = savedCustomUrlUI;

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            NSString *fileUrl = [alert textFieldAtIndex:0].text;

            GetSocialConfiguration *config = [GetSocial sharedInstance].configuration;
            [config setConfiguration:fileUrl];

            GroupedCheckableMenuItem *menuItem = (GroupedCheckableMenuItem *)[self.uiCustomizationMenu menuItemWithName:@"customUrlUI"];
            menuItem.isChecked = YES;

            self.uiCustomizationMenu.detail = @"Current UI: Custom Url";

            [[NSUserDefaults standardUserDefaults] setObject:fileUrl forKey:@"GetSocialUIConfigurationCustomURL"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];

    return NO;
}

#pragma mark - Cloud Save

- (void)saveState
{
    UIBAlertView *alert =
        [[UIBAlertView alloc] initWithTitle:@"Cloud Save" message:@"Enter content to save" cancelButtonTitle:@"Cancel" otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            [[GetSocial sharedInstance] saveState:[alert textFieldAtIndex:0].text
                success:^{
                    GSLogInfo(YES, NO, @"State saved succesfully.");
                }
                failure:^(NSError *error) {
                    GSLogInfo(YES, NO, @"Failed to save State. Reason: %@.", [error localizedDescription]);
                }];
        }
    }];
}

- (void)getSavedState
{
    [[GetSocial sharedInstance] savedStateWithSuccess:^(NSString *state) {
        GSLogInfo(YES, NO, @"Saved State retrieved: %@.", state);
    }
        failure:^(NSError *error) {
            GSLogInfo(YES, NO, @"Failed to retrieve Saved State. Reason: %@.", [error localizedDescription]);
        }];
}

#pragma mark - Console

- (void)openConsole
{
    [self.mainNavigationController pushViewController:[ConsoleViewController sharedController] animated:YES];
}

- (void)log:(LogLevel)level context:(NSString *)context message:(NSString *)message showAlert:(BOOL)showAlert showConsole:(BOOL)showConsole
{
    [[ConsoleViewController sharedController] log:level message:message context:context];

    if (showAlert)
    {
        switch (level)
        {
            case LogLevelInfo:
                [self showAlertWithTitle:[NSString stringWithFormat:@"Info (%@)", context] andText:message];
                break;

            case LogLevelWarning:
                [self showAlertWithTitle:[NSString stringWithFormat:@"Warning (%@)", context] andText:message];
                break;

            case LogLevelError:
                [self showAlertWithTitle:[NSString stringWithFormat:@"Error (%@)", context] andText:message];
                break;

            default:
                break;
        }
    }

    if (showConsole)
    {
        [self openConsole];
    }
}

#pragma mark - Alerts

- (void)showAlertWithText:(NSString *)text
{
    [self showAlertWithTitle:@"Info" andText:text];
}

- (void)showAlertWithTitle:(NSString *)title andText:(NSString *)text
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];

    alertView = nil;
}

-(void)showAlertAvatarClick:(GetSocialUser *)user
{
    UIBAlertView *alert =
    [[UIBAlertView alloc] initWithTitle:@"Avatar clicked"
                                message:@"Choose option"
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@[ @"Follow user", @"Open chat" ]];
    
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        
        if (didCancel)
        {
            return;
        }
        
        switch (selectedIndex)
        {
            case 1:
            {
                GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;
                if(currentUser)
                {
                    [currentUser followUser:user success:^{
                        GSLogInfo(YES, NO, @"Following user %@ (%@).", user.displayName, user.guid);
                    } failure:^(NSError *error) {
                        GSLogInfo(YES, NO, @"Following user error %@ .", [error description]);
                    }];
                }
                break;
            }
            case 2:
            {
                [[[GetSocialChat sharedInstance] createChatViewForUser:user] show];
                break;
            }
        }
    }];
}

-(void)showAlertFriendClick:(GetSocialUser *)user
{
    UIBAlertView *alert =
    [[UIBAlertView alloc] initWithTitle:@"Friend clicked"
                                message:@"Choose option"
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@[ @"Unfollow user", @"Open chat" ]];
    
    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        
        if (didCancel)
        {
            return;
        }
        
        switch (selectedIndex)
        {
            case 1:
            {
                GetSocialCurrentUser *currentUser = [GetSocial sharedInstance].currentUser;
                if(currentUser)
                {
                    [currentUser unfollowUser:user success:^{
                        GSLogInfo(YES, NO, @"User %@ (%@) was unfollowed.", user.displayName, user.guid);
                    } failure:^(NSError *error) {
                        GSLogInfo(YES, NO, @"Unfollowing user error");
                    }];
                }
                break;
            }
            case 2:
            {
                [[[GetSocialChat sharedInstance] createChatViewForUser:user] show];
                break;
            }
        }
    }];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.mainNavigationController = [segue destinationViewController];
    self.mainNavigationController.menu = self.menu;
}

- (void)dealloc
{
    [[GetSocialChat sharedInstance] removeOnUnreadRoomsCountChangeHandler:self.onUnreadPublicRoomsCountChangeHandler
                                   onUnreadPrivateRoomsCountChangeHandler:self.onUnreadPrivateRoomsCountChangeHandler];
}

@end
