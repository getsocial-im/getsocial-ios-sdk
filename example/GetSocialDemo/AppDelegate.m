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
#import <GetSocial/GetSocial.h>
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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    [[AppsFlyerTracker sharedTracker] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
    [VKSdk processOpenURL:url fromApplication:sourceApplication];
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
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

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler
{
    return [[AppsFlyerTracker sharedTracker] continueUserActivity:userActivity restorationHandler:restorationHandler];
}

@end
