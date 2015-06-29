//
//  GetSocialFacebookPlugin.m
//  testapp
//
//  Created by Demian Denker on 17/11/14.
//  Copyright (c) 2014 GetSocial. All rights reserved.
//

#import "GetSocialFacebookUtils.h"
#import <GetSocial/GetSocial.h>

@implementation GetSocialFacebookUtils

#pragma mark Singleton Methods
+ (instancetype) sharedInstance
{
    static GetSocialFacebookUtils* privateSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        privateSharedInstance = [[self alloc] init];
        privateSharedInstance.accessToken = nil;
    });
    return privateSharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        if ([FBSDKAccessToken currentAccessToken])
        {
            [self updateSessionState];
        }
    }
    return self;
}

- (void) initialize
{
    [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateSessionState];
    }];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) updateSessionState
{
    if ([FBSDKAccessToken currentAccessToken])
    {
        if (self.accessToken == [FBSDKAccessToken currentAccessToken])
        {
            return;
        }
        else
        {
            self.accessToken = [FBSDKAccessToken currentAccessToken];
            
            NSDictionary* info = @{kGetSocialAuthInfoKeyToken:self.accessToken.tokenString, kGetSocialAuthInfoKeyUserId:self.accessToken.userID, kGetSocialAuthInfoKeyExternalUserId:self.accessToken.userID};
            
            [[GetSocial sharedInstance] verifyUserIdentity:info provider:@"facebook" success:^{
                NSLog(@"Game FB Auth -> GetSocial FB Token Auth successful");
            } error:^(NSError *err) {
                NSLog(@"Game FB Auth -> GetSocial FB Token Auth error:%@",[err localizedDescription]);
            }];
        }
    }
    else
    {
        [[GetSocial sharedInstance] clearUserIdentityWithProvider:@"facebook" complete:^{
            NSLog(@"Game FB Logout -> GetSocial Logout complete.");
        }];
    }
}

@end
