/*
 *    	Copyright 2015-2016 GetSocial B.V.
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
#import <GetSocial/GetSocial.h>
#import "ConsoleViewController.h"
#import "Constants.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *key = [info objectForKey:@"GetSocialAppKey"];

    if (key && [key length] > 0)
    {
        [[GetSocial sharedInstance] initWithKey:key
            success:^{

                [[ConsoleViewController sharedController] log:LogLevelInfo message:@"GetSocial Initialization Succeeded." context:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:UserWasUpdatedNotification object:nil];
            }
            failure:^(NSError *error) {

                [[ConsoleViewController sharedController]
                        log:LogLevelError
                    message:[NSString stringWithFormat:@"GetSocial Initialization Failed. Reason: %@.", [error localizedDescription]]
                    context:nil];

            }];
    }
    else
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Missing GetSocial AppKey on the info.plist" userInfo:nil];
    }

    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSDKAppEvents activateApp];
}

@end
