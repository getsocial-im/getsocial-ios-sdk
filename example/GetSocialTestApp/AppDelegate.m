//
//  AppDelegate.m
//  GetSocialTestApp
//
//  Created by Demian Denker on 28/01/15.
//  Copyright (c) 2015 GetSocial. All rights reserved.
//

#import "AppDelegate.h"
#import <GetSocial/GetSocial.h>
#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [FBLoginView class];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [[GetSocial sharedInstance] authenticateGame:@"4We9Uqq8SR04tNXqV10M0000000s8i7N997ga98n" success:^{
        NSLog(@"authenticateGame Succeed");
        
    } failure:^(NSError *error) {
        NSLog(@"authenticateGame Failed");
    }];
    
    return YES;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    return wasHandled;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActive];
}

@end
