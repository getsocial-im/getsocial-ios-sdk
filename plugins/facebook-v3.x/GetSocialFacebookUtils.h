//
//  GetSocialFacebookUtils.h
//  testapp
//
//  Created by Demian Denker on 17/11/14.
//  Copyright (c) 2014 GetSocial. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface GetSocialFacebookUtils : NSObject

+ (instancetype) sharedInstance;

- (void) updateSessionState;

@property (nonatomic, copy) void (^onSessionOpenHandler)();
@property (nonatomic, copy) void (^onSessionCloseHandler)();
@property (nonatomic, weak) FBSession* session;
@property (nonatomic, assign) FBSessionState sessionState;

@end
