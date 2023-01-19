/*
 *    	Copyright 2015-2020 GetSocial B.V.
 *
 *	Licensed under the Apache License, Version 2.0 (the "License");
 *	you may not use this file except in compliance with the License.
 *	You may obtain a copy of the License at
 *
 *    	http://www.apache.org/licenses/LICENSE-2.0
 *
 *	Unless required by applicable law or agreed to in writing, software
 *	distributed under the License is distributed on an "AS IS" BASIS,
 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *	See the License for the specific language governing permissions and
 *	limitations under the License.
 */

#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GetSocialSDK/GetSocialSDK.h>
#import <GetSocialUI/GetSocialUI.h>
#import "ConsoleViewController.h"
#import "Constants.h"
#if DISABLE_TWITTER != 1
#import <TwitterKit/TwitterKit.h>
#endif
#import <AdjustSdk/Adjust.h>
#import <AppsFlyerLib/AppsFlyerTracker.h>
#import <Fabric/Fabric.h>
#import <FirebaseCore/FIRApp.h>
#import "VKSdk.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@import FirebaseCore;
@import FirebaseDynamicLinks;
@import FirebaseMessaging;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:didFinishLaunchingWithOptions: %@", launchOptions]);
    
    if (@available(iOS 14, *)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                [[ConsoleViewController sharedController] log:LogLevelInfo message:[NSString stringWithFormat: @"Tracking status: %d", status] context:nil];
                
                NSString* idfa = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
                [[ConsoleViewController sharedController] log:LogLevelInfo message:[NSString stringWithFormat: @"IDFA: %@", idfa] context:nil];
            }];
        });
    }
    [FIRApp configure];
    
#if DISABLE_TWITTER != 1
    [[Twitter sharedInstance] startWithConsumerKey:@"fiCw1nyiio9pdkim79jgnG7gB" consumerSecret:@"p5F4GHGQcv4faqGBGL3xBsXwD2GNkxvEF8pMcbvaa0LALWw02v"];
#endif
    [self setUpAdjust];
    [self setUpAppsFlyer];
    
    VKSdk *sdkInstance = [VKSdk initializeWithAppId:@"6435876"];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:openURL:sourceApplication: %@, %@, %@", url, sourceApplication, annotation]);
    [[AppsFlyerTracker sharedTracker] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
    [VKSdk processOpenURL:url fromApplication:sourceApplication];
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:openURL: %@, %@", url, options]);
    
    [[AppsFlyerTracker sharedTracker] handleOpenUrl:url options:options];
    [VKSdk processOpenURL:url fromApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];
    
#if DISABLE_TWITTER != 1
    return [[Twitter sharedInstance] application:app openURL:url options:options];
#else
    return false;
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSDKAppEvents activateApp];
    [AppsFlyerTracker.sharedTracker trackAppLaunch];
    
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:applicationDidBecomeActive"]);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [GetSocialUI closeView:NO];
}

- (void)setUpAdjust
{
    NSString *appToken = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"im.getsocial.demo.adjust.AppToken"];
    if (!appToken.length)
    {
        return;
    }
    NSString *environment = ADJEnvironmentProduction;
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:environment];
    
    [Adjust appDidLaunch:adjustConfig];
}

- (void)setUpAppsFlyer
{
    NSString *appToken = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"im.getsocial.demo.appsflyer.AppToken"];
    if (!appToken.length)
    {
        return;
    }
    AppsFlyerTracker.sharedTracker.appsFlyerDevKey = @"AP8P3GvwHgw9NBdBTWAqrb";
    AppsFlyerTracker.sharedTracker.appleAppID = appToken;
}


- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:continueUserActivity: %@, %@", userActivity, restorationHandler]);
    
    BOOL handled = [[FIRDynamicLinks dynamicLinks] handleUniversalLink:userActivity.webpageURL
                                                              completion:^(FIRDynamicLink * _Nullable dynamicLink,
                                                                           NSError * _Nullable error) {
                                                                
        [[ConsoleViewController sharedController] log:LogLevelInfo message:[NSString stringWithFormat: @"Firebase DynamicLink: %@", dynamicLink] context:nil];
    }];

    return [[AppsFlyerTracker sharedTracker] continueUserActivity:userActivity restorationHandler:restorationHandler];
}
    

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:didRegisterForRemoteNotificationsWithDeviceToken: %@", deviceToken]);
    
    [[ConsoleViewController sharedController] log:LogLevelInfo message:[NSString stringWithFormat: @"PN Token: %@", deviceToken] context:nil];
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:didReceiveRemoteNotification:fetchCompletionHandler: %@, %@", userInfo, completionHandler]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:didReceiveRemoteNotification: %@", userInfo]);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)err {
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:didFailToRegisterForRemoteNotificationsWithError: %@", err]);
}


- (void)applicationWillResignActive:(UIApplication *)application{
    NSLog(@"%@", [NSString stringWithFormat: @"Swizzle:applicationWillResignActive"]);
}



@end
