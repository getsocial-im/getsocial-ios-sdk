//
//  GetSocialFacebookUtils.h
//  testapp
//
//  Created by Demian Denker on 17/11/14.
//  Copyright (c) 2014 GetSocial. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface GetSocialFacebookUtils : NSObject

+ (instancetype) sharedInstance;

- (void) updateSessionState;
- (void) initialize;

@property (nonatomic, weak) FBSDKAccessToken* accessToken;

@end
