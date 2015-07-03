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
    });
    return privateSharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.accessToken = nil;
        
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
        if (self.accessToken != [FBSDKAccessToken currentAccessToken])
        {
            self.accessToken = [FBSDKAccessToken currentAccessToken];
            
            if (self.accessToken.userID == nil)
            {
                [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil]
                 startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                     if (!error && result[@"id"]!=nil)
                     {
                         [self verifyUserIdentityWithToken:self.accessToken.tokenString andUserId:result[@"id"]];
                     }
                     else
                     {
                         NSLog(@"Game FB Auth failed (no user Id available)");
                     }
                 }];
            }
            else
            {
                [self verifyUserIdentityWithToken:self.accessToken.tokenString andUserId:self.accessToken.userID];
            }
        }
    }
    else
    {
        [[GetSocial sharedInstance] clearUserIdentityWithProvider:@"facebook" complete:^{
            NSLog(@"Game FB Logout -> GetSocial Logout complete.");
        }];
    }
}

- (void) verifyUserIdentityWithToken:(NSString*) token andUserId:(NSString*) userId
{
    NSDictionary* info = @{kGetSocialAuthInfoKeyToken:token, kGetSocialAuthInfoKeyUserId:userId, kGetSocialAuthInfoKeyExternalUserId:userId};
    
    [[GetSocial sharedInstance] verifyUserIdentity:info provider:@"facebook" success:^{
        NSLog(@"Game FB Auth -> GetSocial FB Token Auth successful");
    } error:^(NSError *err) {
        NSLog(@"Game FB Auth -> GetSocial FB Token Auth error:%@",[err localizedDescription]);
    }];
}

@end
