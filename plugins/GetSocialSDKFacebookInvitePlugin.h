//
//  GetSocialSDKFacebookInvitePlugin.h
//  testapp
//
//  Created by Demian Denker on 17/11/14.
//  Copyright (c) 2014 GetSocial. All rights reserved.
//

#import <GetSocialSDK/GetSocialSDKInvitePlugin.h>

@interface GetSocialSDKFacebookInvitePlugin : GetSocialSDKInvitePlugin

@property (nonatomic, copy) void (^authenticateUserHandler)();

@end
