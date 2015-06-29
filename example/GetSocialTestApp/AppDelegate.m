//
//  AppDelegate.m
//  GetSocialTestApp
//
//  Created by Demian Denker on 28/01/15.
//  Copyright (c) 2015 GetSocial. All rights reserved.
//

#import "AppDelegate.h"
#import <GetSocial/GetSocial.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [FBSDKLoginButton class];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [[GetSocial sharedInstance] authenticateGame:@"4We9Uqq8SR04tNXqV10M0000000s8i7N997ga98n" success:^{
        NSLog(@"authenticateGame Succeed");
        
    } failure:^(NSError *error) {
        NSLog(@"authenticateGame Failed");
    }];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSDKAppEvents activateApp];
}

@end
