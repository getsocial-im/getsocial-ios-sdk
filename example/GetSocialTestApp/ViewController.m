//
//  ViewController.m
//  GetSocialTestApp
//
//  Created by Demian Denker on 28/01/15.
//  Copyright (c) 2015 GetSocial. All rights reserved.
//

#import "ViewController.h"
#import <GetSocial/GetSocial.h>
#import "GetSocialFacebookUtils.h"
#import "GetSocialFacebookInvitePlugin.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register FBInvitePlugin
    GetSocialFacebookInvitePlugin* fbInvitePlugin = [[GetSocialFacebookInvitePlugin alloc] init];
    
    id __weak weakSelf = self;
    fbInvitePlugin.authenticateUserHandler = ^{ [weakSelf loginWithFacebook]; };
    
    [[GetSocial sharedInstance] registerPlugin:fbInvitePlugin provider:@"facebook"];
    
    //Register FBInvitePlugin
    [[GetSocial sharedInstance] setOnLoginRequestHandler:^{
        [self loginWithFacebook];
    }];
    
    [[GetSocial sharedInstance] setOnActivityActionClickHandler:^(NSString *action) {
        [self showAlertWithTitle:@"Action Button Click" andText:[NSString stringWithFormat:@"%@", action]];
    }];
    
    [[GetSocial sharedInstance] setOnInviteButtonClickHandler:^BOOL{
        [self showAlertWithTitle:@"Invite Button Click" andText:@""];
        return NO;
    }];
    
    [[GetSocial sharedInstance] setOnReferralDataReceivedHandler:^(NSArray *referralData) {
        [self showAlertWithTitle:@"Referral data received" andText:[NSString stringWithFormat:@"%@", referralData]];
    }];
    
    [self showVersionNumber];
    
    //set current user language
    [[GetSocial sharedInstance] setLanguage:@"en"];
    
    //set up the FB Login View
    self.loginView.readPermissions = kGetSocialAuthPermissionsFacebook;
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
                              [GetSocial sharedInstance].sdkVersion];
    
    self.versionLabel.layer.zPosition = 999999;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Button Actions

- (IBAction)onShowActivities:(id)sender
{
    [[GetSocial sharedInstance] open:GetSocialViewTypeActivities];
}

- (IBAction)onShowIsolatedActivities:(id)sender
{
    [[GetSocial sharedInstance] open:GetSocialViewTypeActivities withProperties:@{kGetSocialActivityTags:@[@"tag1"],kGetSocialActivityGroup:@"group1"}];
}

- (IBAction)onShowAllNotifications:(id)sender
{
    [[GetSocial sharedInstance] open:GetSocialViewTypeNotifications];
}

-(IBAction)onSmartInvite:(id)sender
{
    [[GetSocial sharedInstance] open:GetSocialViewTypeSmartInvite];
}

-(IBAction)onGlobalChatRoom:(id)sender
{
    [[GetSocial sharedInstance] open:GetSocialViewTypeChat withProperties:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"global",@"Global Chat", nil] forKeys:[NSArray arrayWithObjects:kGetSocialRoomName,kGetSocialTitle, nil]]];
}

#pragma mark - Facebook Integration
- (void)loginWithFacebook
{
    [FBSession openActiveSessionWithReadPermissions:kGetSocialAuthPermissionsFacebook
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      [[GetSocialFacebookUtils sharedInstance] updateSessionState];
                                  }];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    [[GetSocialFacebookUtils sharedInstance] updateSessionState];
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    [[GetSocialFacebookUtils sharedInstance] updateSessionState];
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error
{
    [[GetSocialFacebookUtils sharedInstance] updateSessionState];
}

-(void)showAlertWithTitle:(NSString*)title andText:(NSString*)text
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alertView show];
    
    alertView = nil;
}


@end
