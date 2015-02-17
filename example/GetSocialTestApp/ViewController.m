//
//  ViewController.m
//  GetSocialTestApp
//
//  Created by Demian Denker on 28/01/15.
//  Copyright (c) 2015 GetSocial. All rights reserved.
//

#import "ViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
#import "GetSocialSDKFacebookUtils.h"
#import "GetSocialSDKFacebookInvitePlugin.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register FBInvitePlugin
    GetSocialSDKFacebookInvitePlugin* fbInvitePlugin = [[GetSocialSDKFacebookInvitePlugin alloc] init];
    
    id __weak weakSelf = self;
    fbInvitePlugin.authenticateUserHandler = ^{ [weakSelf loginWithFacebook]; };
    
    [[GetSocialSDK sharedInstance] registerPlugin:fbInvitePlugin provider:@"facebook"];
    
    //Register FBInvitePlugin
    [[GetSocialSDK sharedInstance] setOnLoginRequestHandler:^{
        [self loginWithFacebook];
    }];

    [self showVersionNumber];
    
    //set current user language
    [[GetSocialSDK sharedInstance] setLanguage:@"en"];
    
    //set up the FB Login View
    self.loginView.readPermissions = kGetSocialSDKAuthPermissionsFacebook;
    self.loginView.frame = CGRectMake((self.view.frame.size.width - CGRectGetWidth(self.loginView.frame)) / 2, 20, CGRectGetWidth(self.loginView.frame), CGRectGetHeight(self.loginView.frame));
    self.loginView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.loginView.loginBehavior = FBSessionLoginBehaviorWithFallbackToWebView;
    self.loginView.delegate = self;
}

-(void)showVersionNumber
{
    self.versionLabel.text = [NSString stringWithFormat:@"%@ v%@ / SDK v%@",
                              [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"],
                              [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"],
                              [GetSocialSDK sharedInstance].sdkVersion];
    
    self.versionLabel.layer.zPosition = 999999;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Button Actions

- (IBAction)onShowActivities:(id)sender
{
    [[GetSocialSDK sharedInstance] open:GetSocialSDKViewTypeActivities];
}

- (IBAction)onShowIsolatedActivities:(id)sender
{
    [[GetSocialSDK sharedInstance] open:GetSocialSDKViewTypeActivities withProperties:@{kGetSocialSDKActivityTags:@[@"tag1"],kGetSocialSDKActivityGroup:@"group1"}];
}

- (IBAction)onShowAllNotifications:(id)sender
{
    [[GetSocialSDK sharedInstance] open:GetSocialSDKViewTypeNotifications];
}

-(IBAction)onSmartInvite:(id)sender
{
    [[GetSocialSDK sharedInstance] open:GetSocialSDKViewTypeSmartInvite];
}

#pragma mark - Facebook Integration
- (void)loginWithFacebook
{
    [FBSession openActiveSessionWithReadPermissions:kGetSocialSDKAuthPermissionsFacebook
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      [[GetSocialSDKFacebookUtils sharedInstance] updateSessionState];
                                  }];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    [[GetSocialSDKFacebookUtils sharedInstance] updateSessionState];
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    [[GetSocialSDKFacebookUtils sharedInstance] updateSessionState];
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error
{
    [[GetSocialSDKFacebookUtils sharedInstance] updateSessionState];
}


@end
