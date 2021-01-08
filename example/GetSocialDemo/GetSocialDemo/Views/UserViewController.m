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

#import "UserViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
#import "Constants.h"
#import "UserIdentityViewController.h"

@interface UserViewController ()

@property(weak, nonatomic) IBOutlet UITextView *detailsTextView;

@end

@implementation UserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:UserWasUpdatedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self updateUserDetails];
                                                      });
                                                  }];

    [self updateUserDetails];

    UIBarButtonItem *shareItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    self.navigationItem.rightBarButtonItems = @[ shareItem ];
}

- (void)share
{
    NSString *string = self.detailsTextView.text;

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ string ] applicationActivities:nil];
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)updateUserDetails
{
    if (![GetSocial isInitialized])
    {
        self.detailsTextView.text = @"GetSocial is not initialized.";
        return;
    }
    NSMutableString *details = [NSMutableString string];
    NSMutableDictionary *userDetails = [NSMutableDictionary dictionary];

    [details appendFormat:@"DisplayName: %@\n", GetSocial.currentUser.displayName];
    userDetails[@"DisplayName"] = GetSocial.currentUser.displayName;

    [details appendFormat:@"User ID: %@\n", GetSocial.currentUser.userId];
    userDetails[@"User ID"] = GetSocial.currentUser.userId;

    [details appendFormat:@"Avatar: %@\n", GetSocial.currentUser.avatarUrl];
    userDetails[@"Avatar"] = GetSocial.currentUser.avatarUrl;

    if (!GetSocial.currentUser.isAnonymous)
    {
        userDetails[@"IsAnonymous"] = @NO;
        [details appendString:@"\n\nIdentities\n\n"];
        NSMutableDictionary *identities = [NSMutableDictionary dictionary];
        [GetSocial.currentUser.identities enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
            [details appendFormat:@"Provider: %@\n", key];
            [details appendFormat:@"UserId: %@\n", val];
            [details appendString:@"\n\n"];
            identities[@"Provider"] = key;
            identities[@"Provider User ID"] = val;
        }];
        userDetails[@"Identities"] = identities;
    }
    else
    {
        userDetails[@"IsAnonymous"] = @YES;
        [details appendString:@"\n\nAnonymous\n\n"];
    }

    [details appendString:@"\n\nPublic Properties\n\n"];
    userDetails[@"PublicProperties"] = GetSocial.currentUser.publicProperties;
    [GetSocial.currentUser.publicProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
        [details appendFormat:@"%@: %@\n", key, val];
        [details appendString:@"\n\n"];
    }];

    [details appendString:@"\n\nPrivate Properties\n\n"];
    userDetails[@"PrivateProperties"] = GetSocial.currentUser.privateProperties;
    [GetSocial.currentUser.privateProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
        [details appendFormat:@"%@: %@\n", key, val];
        [details appendString:@"\n\n"];
    }];

    [details appendString:@"\n\nJSON\n\n"];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userDetails options:NSJSONWritingPrettyPrinted error:nil];
    [details appendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];

    self.detailsTextView.text = details;
}

@end
