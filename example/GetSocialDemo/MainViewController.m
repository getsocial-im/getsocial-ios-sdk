/*
 *    	Copyright 2015-2017 GetSocial B.V.
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

#import "UIViewController+GetSocial.h"
#import "ConsoleViewController.h"
#import "Constants.h"
#import "MainNavigationController.h"
#import "MainViewController.h"
#import "MenuItem.h"
#import "UISimpleAlertViewController.h"
#import "UserIdentityUtils.h"
#import "ActivityIndicatorViewController.h"

#import <GetSocial/GetSocial.h>
#import <GetSocial/GetSocialUser.h>
#import <GetSocialUI/GetSocialUI.h>
#import <GetSocial/GetSocialConflictUser.h>

#import "GetSocialFBMessengerInvitePlugin.h"
#import "GetSocialFacebookInvitePlugin.h"
#import "GetSocialKakaoTalkInvitePlugin.h"
#import "MenuTableViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <GetSocial/GetSocialActivityPost.h>
#import <GetSocial/GetSocialUserUpdate.h>
#import <GetSocial/GetSocialConstants.h>
#import <GetSocial/GetSocialAuthIdentity.h>
#import <GetSocial/GetSocialNotificationAction.h>
#import <GetSocial/GetSocialOpenActivityAction.h>


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

#define ExecuteBlock(block, ...)                                          \
    if (block) block(##__VA_ARGS__)

NSString *const kCustomProvider = @"custom";

@interface MainViewController ()<UINavigationControllerDelegate>

@property(nonatomic, strong) ParentMenuItem *uiCustomizationMenu;
@property(nonatomic, strong) ParentMenuItem *languageMenu;
@property(nonatomic, strong) ParentMenuItem *smartInvitesMenu;
@property(nonatomic, strong) ParentMenuItem *activitiesMenu;
@property(nonatomic, strong) ParentMenuItem *settingsMenu;
@property(nonatomic, strong) ParentMenuItem *userAuthenticationMenu;

@property(nonatomic, strong) FBSDKLoginManager *facebookSdkManager;

@property(nonatomic, strong) ActionableMenuItem *friendsMenu;
@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateVersionInfo];

    [self log:LogLevelInfo context:nil message:self.versionLabel.text showAlert:NO showConsole:NO];

    [self setUpGetSocial];
}

- (void)setUpGetSocial
{
    [GetSocial setNotificationActionHandler:^BOOL(GetSocialNotificationAction *action) {
        //handle action here
        return NO;
    }];
    [GetSocialUser setOnUserChangedHandler:^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        [self updateFriendsCount];
    }];

    // Register FBInvitePlugin
    GetSocialFacebookInvitePlugin *fbInvitePlugin = [[GetSocialFacebookInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:fbInvitePlugin forChannelId:GetSocial_InviteChannelPluginId_Facebook];

    // Register FB Messenger Invite Plugin
    GetSocialFBMessengerInvitePlugin *fbMessengerPlugin = [[GetSocialFBMessengerInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:fbMessengerPlugin forChannelId:GetSocial_InviteChannelPluginId_Facebook_Messenger];

    // Register KakaoTalk Invite Plugin
    GetSocialKakaoTalkInvitePlugin *kakaoTalkPlugin = [[GetSocialKakaoTalkInvitePlugin alloc] init];
    [GetSocial registerInviteChannelPlugin:kakaoTalkPlugin forChannelId:GetSocial_InviteChannelPluginId_Kakao];
}

- (void)updateFriendsCount
{
    if (![GetSocial isInitialized]) {
        return;
    }
    [GetSocialUser friendsCountWithSuccess:^(int result) {
        self.friendsMenu.detail = [NSString stringWithFormat:@"You have %d friends", result];
    } failure:^(NSError *error) {
        GSLogError(NO, NO, @"Error updating friends count: %@", error.localizedDescription);
    }];
}

- (void)awakeFromNib
{
    [self loadMenu];
    [super awakeFromNib];
}

- (void)updateVersionInfo
{
    self.versionLabel.text =
            [NSString stringWithFormat:@"GetSocial iOS Demo\nSDK v%@. Build v%@.",
                                       [GetSocial sdkVersion],
                                       [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]
            ];
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
        
        [self.menu addObject:self.userAuthenticationMenu];
        
        // Friends Menu
        [self.menu addObject:self.friendsMenu = [MenuItem actionableMenuItemWithTitle:@"Friends" action:^{
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

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Check Referral Data"
                                                                         action:^{
                                                                             [self checkReferralData];
                                                                         }]];

        [self.smartInvitesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Invite without UI"
                                                                         action:^{
                                                                             [self inviteWithoutUI];
                                                                         }]];

        [self.menu addObject:self.smartInvitesMenu];

        // AF menu
        self.activitiesMenu = [MenuItem parentMenuItemWithTitle:@"Activity Feed"];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Global Activity Feed" action:^{
            GetSocialUIActivityFeedView *activityFeedView = [GetSocialUI createGlobalActivityFeedView];
            [activityFeedView setActionListener:^(NSString *action, GetSocialActivityPost *post) {
                GSLogInfo(YES, NO, @"Activity Feed button clicked, action: %@", action);
            }];
            [activityFeedView show];
        }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Custom Activity Feed (DemoFeed)" action:^{
            GetSocialUIActivityFeedView *activityFeedView = [GetSocialUI createActivityFeedView:@"DemoFeed"];
            [activityFeedView setActionListener:^(NSString *action, GetSocialActivityPost *post) {
                GSLogInfo(YES, NO, @"Activity Feed button clicked, action: %@", action);
            }];
            [activityFeedView show];
        }]];

        [self.activitiesMenu addSubmenu:[MenuItem actionableMenuItemWithTitle:@"Post Activity" action:^{
            [self openPostActivityView];
        }]];

        [self.menu addObject:self.activitiesMenu];

        // UI Customization Menu
        self.uiCustomizationMenu = [MenuItem parentMenuItemWithTitle:@"UI Customization"];
        self.uiCustomizationMenu.detail = @"Current UI: Default";

        [self.uiCustomizationMenu addSubmenu:[MenuItem groupedCheckableMenuItemWithTitle:@"Default UI"
                                                                               isChecked:YES
                                                                                  action:^BOOL(BOOL isChecked) {
                                                                                      return [self loadDefaultUI];
                                                                                  }]];

        [self.menu addObject:self.uiCustomizationMenu];

        // Settings Menu
        self.settingsMenu = [MenuItem parentMenuItemWithTitle:@"Settings"];


        self.languageMenu = [MenuItem parentMenuItemWithTitle:@"Change Language"];
        NSString* currentLanguage = [GetSocial language];
        if (currentLanguage != nil)
        {
            [self changeLanguage: currentLanguage];
        }

        NSDictionary *availableLanguages = [GetSocialConstants allLanguageCodes];

        NSArray *sortedLanguages = [[availableLanguages allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [availableLanguages[obj1] localizedCaseInsensitiveCompare:availableLanguages[obj2]];
        }];
        
        for (NSString *key in sortedLanguages)
        {
            MenuItem* menuItem = [MenuItem groupedCheckableMenuItemWithTitle:availableLanguages[key]
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
                                                              if(currentLanguage != nil)
                                                              {
                                                                  [self changeLanguage:currentLanguage];
                                                                  
                                                                  for(CheckableMenuItem* menuItem in weakSelf.languageMenu.subitems)
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
        
        [self.menu addObject:self.settingsMenu];

    }
}

#pragma mark - Authentication

- (FBSDKLoginManager *)facebookSdkManager
{
    if (!_facebookSdkManager)
    {
        _facebookSdkManager = [FBSDKLoginManager new];
        _facebookSdkManager.loginBehavior = FBSDKLoginBehaviorWeb;
    }
    return _facebookSdkManager;
}

- (void)loginWithFacebookWithHandler:(FBSDKLoginManagerRequestTokenHandler)handler
{
    
    [self.facebookSdkManager logInWithReadPermissions:@[@"email", @"user_friends"] fromViewController:self handler:handler];
}

- (void)changeUserAvatar
{
    [self showActivityIndicator];
    [GetSocialUser setAvatarUrl:[UserIdentityUtils randomAvatarUrl] success:^{
        [self hideActivityIndicator];
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        GSLogInfo(YES, NO, @"User avatar has been successfully updated");
    } failure:^(NSError *error) {
        [self hideActivityIndicator];
        GSLogError(YES, NO, @"Error changing user avatar: %@", error.description);
    }];
}

- (void)changeDisplayName
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Change Display Name"
                                                      message:@"Enter new display name"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[@"Ok"]];

    [alert addTextFieldWithPlaceholder:nil defaultText:[UserIdentityUtils randomDisplayName] isSecure:NO];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel) {
            [self showActivityIndicator];
            NSString* newDisplayName = [alert contentOfTextFieldAtIndex:0];
            [GetSocialUser setDisplayName:newDisplayName success:^{
                [self hideActivityIndicator];
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
                GSLogInfo(YES, NO, @"User display name has been successfully updated");
            } failure:^(NSError *error) {
                [self hideActivityIndicator];
                GSLogError(YES, NO, @"Error changing user display name: %@", error.description);
            }];
        }
    } onViewController:self];
}

- (void)addFBUserIdentityWithSuccess:(void (^)())success failure:(void (^)())failure
{
    NSDictionary *authIdentities = [GetSocialUser authIdentities];
    if (!authIdentities[GetSocial_AuthIdentityProviderId_Facebook])
    {
        [self loginWithFacebookWithHandler:^(FBSDKLoginManagerLoginResult *result, NSError *loginError) {
            if (!loginError && !result.isCancelled)
            {
                [self addIdentity:[GetSocialAuthIdentity facebookIdentityWithAccessToken:result.token.tokenString]
                          success:success
                          failure:failure];
            }
        }];
    } else
    {
        GSLogInfo(YES, NO, @"User has already a Facebook identity.");
    }
}

- (void)removeFBUserIdentity
{
    [self.facebookSdkManager logOut];
    if ([[GetSocialUser authIdentities] objectForKey:GetSocial_AuthIdentityProviderId_Facebook] != nil)
    {
        [self showActivityIndicator];
        [GetSocialUser removeAuthIdentityWithProviderId:GetSocial_AuthIdentityProviderId_Facebook success:^{
            [self hideActivityIndicator];
            GSLogInfo(YES, NO, @"Identity removed for Provider %@.", GetSocial_AuthIdentityProviderId_Facebook);
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        }                                       failure:^(NSError *error) {
            [self hideActivityIndicator];
            GSLogError(YES, NO, @"Failed to remove Identity for Provider %@, error: %@", GetSocial_AuthIdentityProviderId_Facebook,
                    [error localizedDescription]);
        }];
    } else
    {
        GSLogWarning(YES, NO, @"User doesn't have UserIdentity for Provider %@.", GetSocial_AuthIdentityProviderId_Facebook);
    }
}

- (void)addCustomUserIdentityWithSuccess:(void (^)())success failure:(void (^)())failure
{
    UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Add Custom User identity"
                                                      message:@"Enter UserId and Token"
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@[@"Ok"]];

    [alert addTextFieldWithPlaceholder:@"UserId" defaultText:nil isSecure:NO];
    [alert addTextFieldWithPlaceholder:@"Token" defaultText:nil isSecure:YES];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
        if (!didCancel) {
            NSString *providerId = kCustomProvider;
            NSString *providerUserId = [alert contentOfTextFieldAtIndex:0];
            NSString *accessToken = [alert contentOfTextFieldAtIndex:1];

            GetSocialAuthIdentity *identity = [GetSocialAuthIdentity customIdentityForProvider:providerId userId:providerUserId accessToken:accessToken];

            [self addIdentity:identity success:success failure:failure];
        }
    } onViewController:self];
}

- (void)removeCustomUserIdentity
{
    if ([[GetSocialUser authIdentities] objectForKey:kCustomProvider])
    {
        [self showActivityIndicator];
        [GetSocialUser removeAuthIdentityWithProviderId:kCustomProvider success:^{
            [self hideActivityIndicator];
            GSLogInfo(YES, NO, @"User identity removed for Provider '%@'", kCustomProvider);
            [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        }                                       failure:^(NSError *error) {
            [self hideActivityIndicator];
            GSLogError(YES, NO, @"Failed to remove user identity for Provider '%@', error: %@", kCustomProvider, [error localizedDescription]);
        }];
    } else
    {
        GSLogWarning(YES, NO, @"User doesn't have user identity for Provider '%@'", kCustomProvider);
    }
}

- (void)addIdentity:(GetSocialAuthIdentity *)identity success:(void (^)())success failure:(void (^)())failure
{
    [self showActivityIndicator];
    [GetSocialUser addAuthIdentity:identity
                           success:^{
                               [self hideActivityIndicator];
                               GSLogInfo(YES, NO, @"User identity %@ added, result: Identity added", identity);
                               [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
                               ExecuteBlock(success);
                           } conflict:^(GetSocialConflictUser *conflictUser) {
                               [self hideActivityIndicator];
                [self showAlertViewToResolveIdentityConflictWithConflictUser:conflictUser conflictResolution:^(BOOL switchUser) {
                    if (switchUser)
                    {
                        [self callSwitchUserWithIdentity:identity
                                                 success:success
                                                 failure:failure];
                    }
                }];
            } failure:^(NSError *error) {
                [self hideActivityIndicator];
                GSLogError(YES, NO, @"Failed to add user identity %@, error: %@", identity, [error localizedDescription]);
                ExecuteBlock(failure);
            }];
}

- (void)callSwitchUserWithIdentity:(GetSocialAuthIdentity *)identity
                           success:(void (^)())success
                           failure:(void (^)())failure
{
    [self showActivityIndicator];
    [GetSocialUser switchUserToIdentity:identity success:^{
        [self hideActivityIndicator];
        [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
        GSLogInfo(YES, NO, @"User switching was successfull.");
        ExecuteBlock(success);
    }                               failure:^(NSError *error) {
        [self hideActivityIndicator];
        GSLogInfo(YES, NO, @"User switching failed, error: %@", [error description]);
        ExecuteBlock(failure);
    }];
}

- (void)showAlertViewToResolveIdentityConflictWithConflictUser:(GetSocialConflictUser *)conflictUser conflictResolution:(void (^)(BOOL switchUser))conflictResolution
{
    UISimpleAlertViewController *alert =
            [[UISimpleAlertViewController alloc] initWithTitle:@"Conflict"
                                        message:@"The new identity is already linked to another user. Which one do you want to continue using?"
                              cancelButtonTitle:[NSString stringWithFormat:@"%@ (Remote)", [conflictUser userId]]
                              otherButtonTitles:@[[NSString stringWithFormat:@"%@ (Current)", [GetSocialUser userId]]]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            BOOL switchUser = didCancel;
            if (conflictResolution)
            {
                conflictResolution(switchUser);
            }
        } onViewController:self];
    });
}

#pragma mark - Friends

- (void)openFriends
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Friends"];
    [self.mainNavigationController pushViewController:vc animated:YES];
}

#pragma mark - Smart Invites

- (void)openSmartInvites
{
    [[GetSocialUI createInvitesView] show];
}

- (void)checkReferralData
{
    [self showActivityIndicator];
    [GetSocial referralDataWithSuccess:^(GetSocialReferralData * _Nullable referralData) {
        [self hideActivityIndicator];
        if (referralData == nil)
        {
            GSLogInfo(YES, NO, @"No referral data");
        }
        else
        {
            GSLogInfo(YES, NO, @"Referral data received: token: %@, referrerUserId: %@, referrerChannelId: %@, isFirstMatch: %i customData: %@.",
                    [referralData token], [referralData referrerUserId], [referralData referrerChannelId], [referralData isFirstMatch], [referralData customData]);
        }
    } failure:^(NSError * _Nonnull error) {
        [self hideActivityIndicator];
        GSLogInfo(YES, NO, @"Could not get referral data: %@", [error description]);
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

    UISimpleAlertViewController *alert =
            [[UISimpleAlertViewController alloc] initWithTitle:@"Smart Invite" message:@"Choose provider" cancelButtonTitle:@"Cancel" otherButtonTitles:providerNames];

    [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {

        if (!didCancel)
        {
            NSString *selectedProviderId = [[channels objectAtIndex:selectedIndex] channelId];
            [self performSelector:@selector(callSendInviteWithProviderId:) withObject:selectedProviderId afterDelay:.5f];
        }
    } onViewController:self];
}

- (void)callSendInviteWithProviderId:(NSString *)providerId
{
    [self showActivityIndicator];
    [GetSocial sendInviteWithChannelId:providerId success:^{
        [self hideActivityIndicator];
        GSLogInfo(NO, NO, @"Sending invites was successful");
    }                           cancel:^{
        [self hideActivityIndicator];
        GSLogInfo(NO, NO, @"Sending invites was cancelled");
    }                          failure:^(NSError *error) {
        [self hideActivityIndicator];
        GSLogInfo(NO, NO, @"Sending invites failed, error: %@", [error description]);
    }];
}

- (void)openCustomizedSmartInvite
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CustomSmartInvite"];
    [self.mainNavigationController pushViewController:vc animated:YES];
}

#pragma mark - Activities

- (void)openPostActivityView
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PostActivity"];
    [self.mainNavigationController pushViewController:vc animated:YES];
}

#pragma mark - Localization

- (BOOL)changeLanguage:(NSString *)language
{
    [GetSocial setLanguage:language];
    self.languageMenu.detail = [NSString stringWithFormat:@"Current language: %@", [GetSocialConstants allLanguageCodes][language]];
    GSLogInfo(NO, NO, @"Language changed to: %@.", language);
    return YES;
}

#pragma mark - UI Customization

- (BOOL)loadDefaultUI
{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationUnknown) forKey:@"orientation"];

    [GetSocialUI loadDefaultConfiguration];

    self.uiCustomizationMenu.detail = @"Current UI: Default";
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.mainNavigationController = [segue destinationViewController];
    self.mainNavigationController.menu = self.menu;
    self.mainNavigationController.delegate = self;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[MenuTableViewController class]])
    {
        [self updateFriendsCount];
    }
}

@end
