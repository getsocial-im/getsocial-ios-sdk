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
        privateSharedInstance.session = nil;
    });
    return privateSharedInstance;
}

- (void) updateSessionState
{
    if ([FBSession activeSession]!=nil)
    {
        if (self.session == [FBSession activeSession] && self.sessionState == [FBSession activeSession].state)
        {
            return;
        }
        else
        {
            self.session = [FBSession activeSession];
            self.sessionState = [FBSession activeSession].state;
        }
        
        if (self.session.isOpen)
        {
            /* make the API call */
            [FBRequestConnection startWithGraphPath:@"/me"
                                         parameters:nil
                                         HTTPMethod:@"GET"
                                  completionHandler:^(
                                                      FBRequestConnection *connection,
                                                      id result,
                                                      NSError *error
                                                      ) {
                                      
                                      NSString* userId = @"";
                                      if (!error)
                                      {
                                          userId = [result objectForKey:@"id"];
                                      }
                                      
                                      NSDictionary* info = @{kGetSocialAuthInfoKeyToken:[FBSession activeSession].accessTokenData.accessToken, kGetSocialAuthInfoKeyUserId:userId, kGetSocialAuthInfoKeyExternalUserId:userId};
                                      
                                      [[GetSocial sharedInstance] verifyUserIdentity:info provider:@"facebook" success:^{
                                          NSLog(@"Game FB Auth -> GetSocial FB Token Auth successful");
                                          
                                          if (self.onSessionOpenHandler)
                                          {
                                              self.onSessionOpenHandler();
                                              self.onSessionOpenHandler = nil;
                                              self.onSessionCloseHandler = nil;
                                          }
                                          
                                      } error:^(NSError *err) {
                                          NSLog(@"Game FB Auth -> GetSocial FB Token Auth error:%@",[err localizedDescription]);
                                          
                                          self.onSessionOpenHandler = nil;
                                          self.onSessionCloseHandler = nil;
                                      
                                      }];
                                  }];
        }
        else
        {
            [[GetSocial sharedInstance] clearUserIdentityWithProvider:@"facebook" complete:^{
                NSLog(@"Game FB Logout -> GetSocial Logout complete.");
                
                if (self.onSessionCloseHandler)
                {
                    self.onSessionCloseHandler();
                    self.onSessionOpenHandler = nil;
                    self.onSessionCloseHandler = nil;
                }
            }];
        }
    }
}

@end
