/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "AppDelegate.h"
#import <GetSocial/GetSocial.h>
#import "ConsoleViewController.h"

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
