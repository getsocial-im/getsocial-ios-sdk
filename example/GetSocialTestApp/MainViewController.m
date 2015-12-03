/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "MainViewController.h"
#import "MainNavigationController.h"
#import "MenuItem.h"
#import "ConsoleViewController.h"
#import "UIBAlertView.h"
#import "UserIdentityUtils.h"

#import <GetSocial/GetSocial.h>
#import <GetSocialChat/GetSocialChat.h>

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

@interface MainViewController ()

@property(nonatomic, strong) ConsoleViewController *consoleViewController;
@property(nonatomic, strong) ParentMenuItem *uiCustomizationMenu;
@property(nonatomic, strong) ParentMenuItem *chatMenu;
@property(nonatomic, strong) ParentMenuItem *languageMenu;
@property(nonatomic, strong) ParentMenuItem *notificationCenterMenu;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateVersionInfo];

    [self log:LogLevelInfo context:nil message:self.versionLabel.text showAlert:NO showConsole:NO];
    
    if ([FBSDKAccessToken currentAccessToken])
    {
        [self loginWithFacebookWithToken:[FBSDKAccessToken currentAccessToken].tokenString userId:[FBSDKAccessToken currentAccessToken].userID success:nil failure:nil];
    }

    // Register OnLoginRequestHandler
    [[GetSocial sharedInstance] setOnLoginRequestHandler:^{
        [[GetSocial sharedInstance] closeView:YES];
        [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            
            if (!error && !result.isCancelled)
            {
                [self loginWithFacebookWithToken:result.token.tokenString userId:result.token.userID success:^{
                    [[GetSocial sharedInstance] restoreView];
                } failure:^(NSError *err) {
                    [[GetSocial sharedInstance] restoreView];
                }];
            }
        }];
    }];

    [[GetSocial sharedInstance] setOnReferralDataReceivedHandler:^(NSArray *referralData) {
        GSLogInfo(YES, NO, @"Referral data received: %@.", referralData);
    }];

    [[GetSocial sharedInstance] setOnNotificationsChangeHandler:^(NSInteger unreadNotificationsCount) {
        [self updateUnreadNotificationsCount];
        GSLogInfo(NO, NO, @"Unread Notification count changed to %zd.", unreadNotificationsCount);
    }];

    [[GetSocialChat sharedInstance] setOnChatNotificationsChangeHandler:^(NSInteger unreadNotificationsCount) {
        [self updateUnreadConversationsCount];
        GSLogInfo(NO, NO, @"Chat Unread conversation count changed to %zd,", unreadNotificationsCount);
    }];
    
    [[GetSocial sharedInstance] setOnUserIdentityUpdatedHandler:^(GetSocialUserIdentity *userIdentity) {
        GSLogInfo(NO, NO, @"User Identity was updated.");
    }];
    
    // Register FBInvitePlugin
    GetSocialFacebookInvitePlugin *fbInvitePlugin = [[GetSocialFacebookInvitePlugin alloc] init];
    [[GetSocial sharedInstance] registerPlugin:fbInvitePlugin provider:kGetSocialProviderFacebook];
}

- (void)updateUnreadConversationsCount
{
    self.chatMenu.detail = [NSString stringWithFormat:@"Unread conversations: %zd", [GetSocialChat sharedInstance].unreadConversationsCount];
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
    self.versionLabel.text = [NSString stringWithFormat:@"GetSocial iOS Test App\nSDK v%@", [GetSocial sharedInstance].sdkVersion];
}

- (void)loadMenu
{
    if (!self.menu)
    {
        self.menu = [NSMutableArray array];

        // User Authentication Menu
        ParentMenuItem *userAuthenticationMenu = [MenuItem parentMenuItemWithTitle:@"User Authentication"];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Log in with Facebook"
                                                                          action:^{
                                                                              [self loginWithFacebook];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Log in with Generic provider"
                                                                          action:^{
                                                                              [self loginWithGenericProvider];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Add Facebook user identity"
                                                                          action:^{
                                                                              [self addFBUserIdentity];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Add Custom user identity"
                                                                          action:^{
                                                                              [self addCustomUserIdentity];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Remove Facebook user identity"
                                                                          action:^{
                                                                              [self removeFBUserIdentity];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Remove Custom user identity"
                                                                          action:^{
                                                                              [self removeCustomUserIdentity];
                                                                          }]];

        [userAuthenticationMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Log out"
                                                                          action:^{
                                                                              [self logout];
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
        ParentMenuItem *postActivitiesMenu = [MenuItem parentMenuItemWithTitle:@"Post Activities"];

        [postActivitiesMenu
            addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Text"
                                                      action:^{
                                                          [self postActivity:@"Text" withImage:nil buttonText:nil action:nil andTags:nil];
                                                      }]];

        [postActivitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:
                                                     @"Post Image" action:^{
                                [self postActivity:nil withImage:[UIImage imageNamed:@"activityImage.png"] buttonText:nil action:nil andTags:nil];
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

        [self.menu addObject:smartInvitesMenu];

        // Chat Menu
        self.chatMenu = [MenuItem parentMenuItemWithTitle:@"Chat"];

        [self.chatMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open global chat"
                                                                 action:^{
                                                                     [self openGlobalChat];
                                                                 }]];

        [self.chatMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open conversation list"
                                                                 action:^{
                                                                     [self openChatList];
                                                                 }]];

        [self.menu addObject:self.chatMenu];

        // Notification Center Menu
        self.notificationCenterMenu = [MenuItem parentMenuItemWithTitle:@"Notification Center"];

        [self.notificationCenterMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Open"
                                                                               action:^{
                                                                                   [self openNotificationCenter];
                                                                               }]];

        [self.menu addObject:self.notificationCenterMenu];

        // Friends Menu
        ActionableMenuItem *friendsMenu = [MenuItem actionableMenuItemWithTitle:@"Friend List"
                                                                         action:^{
                                                                             [self openFriendList];
                                                                         }];

        [self.menu addObject:friendsMenu];

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

        [leaderboardsMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Get first 5 scores from Leaderboard 1"
                                                                    action:^{
                                                                        [self getFirst5ScoresFromLeaderboard1];
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

        // Settings Menu
        ParentMenuItem *settingsMenu = [MenuItem parentMenuItemWithTitle:@"Settings"];

        NSString *currentLanguage = [GetSocial sharedInstance].language;

        self.languageMenu = [MenuItem parentMenuItemWithTitle:@"Change Language"];
        self.languageMenu.detail = [NSString stringWithFormat:@"Current language: %@", currentLanguage];

        NSDictionary *availableLanguages = @{
            @"da" : @"Danish",
            @"de" : @"German",
            @"en" : @"English",
            @"es" : @"Spanish",
            @"fr" : @"French",
            @"it" : @"Italian",
            @"nb" : @"Norwegian",
            @"nl" : @"Dutch",
            @"pt" : @"Portuguese",
            @"ru" : @"Russian",
            @"sv" : @"Swedish",
            @"tr" : @"Turkish",
            @"is" : @"Icelandic",
            @"ja" : @"Japanese",
            @"ko" : @"Korean",
            @"zh-Hans" : @"Chinese Simplified",
            @"zh-Hant" : @"Chinese Traditional"
        };

        NSArray *sortedLanguages = [[availableLanguages allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 localizedCaseInsensitiveCompare:obj2];
        }];

        for (NSString *key in sortedLanguages)
        {
            [self.languageMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:availableLanguages[key]
                                                                            isChecked:[currentLanguage isEqualToString:key]
                                                                               action:^BOOL(BOOL isChecked) {
                                                                                   return [self changeLanguage:key];
                                                                               }]];
        }

        [settingsMenu addSubmenu:self.languageMenu];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Enable User Generated Content Handler"
                                                            isChecked:NO
                                                               action:^BOOL(BOOL isChecked) {
                                                                   return [self enableUserGeneratedContentHandler:isChecked];
                                                               }]];

        [settingsMenu addSubmenu:[MenuItem checkableMenuItemWithTitle:@"Custom user avatar click behaviour"
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

        [self.menu addObject:settingsMenu];
    }
}

#pragma mark - Authentication

- (void)loginWithFacebook
{
    [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {

        if (!error && !result.isCancelled)
        {
            [self loginWithFacebookWithToken:result.token.tokenString userId:result.token.userID success:nil failure:nil];
        }
    }];
}

- (void)loginWithFacebookWithToken:(NSString *)token userId:(NSString *)userId success:(void (^)())success failure:(void (^)(NSError *))failure
{
    GetSocialIdentityInfo *info = [GetSocialIdentityInfo identityInfoWithProvider:kGetSocialProviderFacebook token:token userId:userId];

    [[GetSocial sharedInstance] loginWithInfo:info
        success:^{
            GSLogInfo(NO, NO, @"App FB Auth -> GetSocial log in.");

            if (success)
            {
                success();
            }
        }
        failure:^(NSError *err) {
            GSLogError(YES, NO, @"App FB Auth -> GetSocial log in failed: %@.", [err localizedDescription]);

            if (failure)
            {
                failure(err);
            }
        }];
}

- (void)loginWithFacebookWithHandler:(FBSDKLoginManagerRequestTokenHandler)handler
{
    FBSDKLoginManager *login = [FBSDKLoginManager new];
    [login logInWithReadPermissions:kGetSocialAuthPermissionsFacebook fromViewController:self handler:handler];
}

- (void)loginWithGenericProvider
{
    NSString* userId = [UserIdentityUtils installationIdWithSuffix:@"L"];
    
    GetSocialIdentityInfo *info = [GetSocialIdentityInfo identityInfoWithProvider:kGetSocialProviderGeneric
                                                                           userId:userId
                                                                      displayName:[UserIdentityUtils displayNameForUserId:userId]
                                                                        avatarUrl:[UserIdentityUtils avatarUrlForUserId:userId]];


    [[GetSocial sharedInstance] loginWithInfo:info
        success:^{
            GSLogInfo(NO, NO, @"User %@ (%@) logged in using Provider %@", info.displayName, info.userId, info.provider);
        }
        failure:^(NSError *err) {
            GSLogInfo(YES, NO, @"Failed to login user %@ (%@) with Provider %@. Reason: %@", info.displayName, info.userId, info.provider,
                      [err localizedDescription]);
        }];
}

- (void)addFBUserIdentity
{
    if ([GetSocial sharedInstance].isUserLoggedIn)
    {
        if (![[GetSocial sharedInstance].loggedInUser idForProvider:kGetSocialProviderFacebook])
        {
            [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {

                if (!error && !result.isCancelled)
                {
                    GetSocialIdentityInfo *info = [GetSocialIdentityInfo identityInfoWithProvider:kGetSocialProviderFacebook
                                                                                            token:result.token.tokenString
                                                                                           userId:result.token.userID];

                    [[GetSocial sharedInstance] addUserIdentityInfo:info
                        success:^{
                            GSLogInfo(NO, NO, @"App FB Auth -> GetSocial FB User Identity added.");
                        }
                        failure:^(NSError *err) {
                            GSLogError(YES, NO, @"App FB Auth -> GetSocial FB User Identity added failed: %@.", [err localizedDescription]);
                        }];
                }

            }];
        }
        else
        {
            GSLogInfo(YES, NO, @"User is already logged in with Facebook.");
        }
    }
    else
    {
        GSLogWarning(YES, NO, @"User is not logged in.", nil);
    }
}

- (void)removeFBUserIdentity
{
    if ([FBSDKAccessToken currentAccessToken])
    {
        FBSDKLoginManager *login = [FBSDKLoginManager new];
        [login logOut];

        if ([GetSocial sharedInstance].isUserLoggedIn)
        {
            if ([[GetSocial sharedInstance].loggedInUser idForProvider:kGetSocialProviderFacebook])
            {
                [[GetSocial sharedInstance] removeUserIdentityInfoForProvider:kGetSocialProviderFacebook
                    success:^{
                        GSLogInfo(YES, NO, @"UserIdentity removed for Provider %@.", kGetSocialProviderFacebook);
                    }
                    failure:^(NSError *err) {
                        GSLogError(YES, NO, @"Failed to remove UserIdentity for Provider %@.", kGetSocialProviderFacebook);
                    }];
            }
            else
            {
                GSLogWarning(YES, NO, @"User doesn't have UserIdentity for Provider %@.", kGetSocialProviderFacebook);
            }
        }
        else
        {
            GSLogWarning(YES, NO, @"User is not logged in.", nil);
        }
    }
    else
    {
        GSLogWarning(YES, NO, @"User is not logged in with FB.", nil);
    }
}

- (void)addCustomUserIdentity
{
    if ([GetSocial sharedInstance].isUserLoggedIn)
    {
        NSString* userId = [UserIdentityUtils installationIdWithSuffix:@"A"];
        
        GetSocialIdentityInfo *info = [GetSocialIdentityInfo identityInfoWithProvider:@"getsocial"
                                                                               userId:userId
                                                                          displayName:[UserIdentityUtils displayNameForUserId:userId]
                                                                            avatarUrl:[UserIdentityUtils avatarUrlForUserId:userId]];
        
        [[GetSocial sharedInstance] addUserIdentityInfo:info
            success:^{
                GSLogInfo(YES, NO, @"UserIdentity added %@ for Provider %@", info.userId, @"getsocial");
            }
            failure:^(NSError *err) {
                GSLogError(YES, NO, @"Failed to add UserIdentity %@ for Provider %@", info.userId, @"getsocial");
            }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User is not logged in.", nil);
    }
}

- (void)removeCustomUserIdentity
{
    if ([GetSocial sharedInstance].isUserLoggedIn)
    {
        if ([[GetSocial sharedInstance].loggedInUser idForProvider:@"getsocial"])
        {
            [[GetSocial sharedInstance] removeUserIdentityInfoForProvider:@"getsocial"
                success:^{
                    GSLogInfo(YES, NO, @"UserIdentity removed for Provider %@", @"getsocial");
                }
                failure:^(NSError *err) {
                    GSLogError(YES, NO, @"Failed to remove UserIdentity for Provider %@", @"getsocial");
                }];
        }
        else
        {
            GSLogWarning(YES, NO, @"User doesn't have UserIdentity for Provider %@", @"getsocial");
        }
    }
    else
    {
        GSLogWarning(YES, NO, @"User is not logged in.", nil);
    }
}

- (void)logout
{
    if ([GetSocial sharedInstance].isUserLoggedIn)
    {
        [[GetSocial sharedInstance] logoutWithComplete:^{
            GSLogInfo(NO, NO, @"Log out completed.", nil);
        }];
    }
    else
    {
        GSLogWarning(YES, NO, @"User is not logged in.", nil);
    }
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

#pragma mark - Friends

- (void)openFriendList
{
    GetSocialUserListViewBuilder *viewBuilder =
        [[GetSocial sharedInstance] createUserListViewWithDismissHandler:^(GetSocialUserIdentity *user, BOOL didCancel) {
            if (!didCancel)
            {
                GSLogInfo(YES, NO, @"User %@ (%@) was selected.", user.displayName, user.guid);
            }
            else
            {
                GSLogInfo(YES, NO, @"User list closed", nil);
            }
        }];
    viewBuilder.title = @"Friends";
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
    viewBuilder.title = @"Chats";
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

- (void)submitScoreToLeaderboard:(NSString *)leaderboardId withTitle:(NSString *)leaderboardTitle
{
    NSInteger rndValue = 1 + arc4random() % (1000 - 1);  // generate random number between 1 and 1000

    UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:leaderboardTitle
                                                      message:@"Enter score to submit"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[ @"Ok" ]];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"%zd", rndValue];
    //[[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel)
        {
            NSString *score = [alert textFieldAtIndex:0].text;

            [[GetSocial sharedInstance] submitLeaderboardScore:[score integerValue]
                forLeaderboardID:leaderboardId
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

    self.languageMenu.detail = [NSString stringWithFormat:@"Current language: %@", language];

    GSLogInfo(NO, NO, @"Language changed to: %@.", language);
    return YES;
}

#pragma mark - Custom Handlers

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

- (BOOL)enableUserGeneratedContentHandler:(BOOL)isChecked
{
    if (isChecked)
    {
        [[GetSocial sharedInstance] setOnUserGeneratedContentHandler:^NSString *(GetSocialUserGeneratedContentType type, NSString *content) {

            NSString *contentType;

            switch (type)
            {
                case GetSocialUserGeneratedContentTypeActivity:
                    contentType = @"Activity";
                    break;

                case GetSocialUserGeneratedContentTypeComment:
                    contentType = @"Comment";
                    break;

                case GetSocialUserGeneratedContentTypeGroupChatMessage:
                    contentType = @"GroupChatMessage";
                    break;

                case GetSocialUserGeneratedContentTypePrivateChatMessage:
                    contentType = @"PrivateChatMessage";
                    break;

                case GetSocialUserGeneratedContentTypePublicChatMessage:
                    contentType = @"PublicChatMessage";
                    break;

                default:
                    break;
            }

            GSLogInfo(NO, NO, @"User Content (%@) was generated \"%@\".", contentType, content);

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
        [[GetSocial sharedInstance] setOnUserAvatarClickHandler:^BOOL(GetSocialUserIdentity *user, GetSocialSourceView source) {
            GSLogInfo(YES, NO, @"Click on user avatar %@ (%@).", user.displayName, user.guid);
            return YES;
        }];
        GSLogInfo(NO, NO, @"User avatar click custom behaviour was set.");
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
    } failure:^(NSError *error) {
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.mainNavigationController = [segue destinationViewController];
    self.mainNavigationController.menu = self.menu;
}

@end
