/*
 *    	Copyright 2015-2017 GetSocial B.V.
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

#import <GetSocial/GetSocial.h>
#import "Constants.h"
#import "UserIdentityViewController.h"
#import "UserViewController.h"

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

    [details appendFormat:@"DisplayName: %@\n", [GetSocialUser displayName]];
    [details appendFormat:@"User ID: %@\n", [GetSocialUser userId]];
    [details appendFormat:@"Avatar: %@\n", [GetSocialUser avatarUrl]];

    if (![GetSocialUser isAnonymous])
    {
        [details appendString:@"\n\nIdentities\n\n"];
        [[GetSocialUser authIdentities] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
            [details appendFormat:@"Provider: %@\n", key];
            [details appendFormat:@"UserId: %@\n", val];
            [details appendString:@"\n\n"];
        }];
    } else
    {
        [details appendString:@"\n\nAnonymous\n\n"];
    }

    self.detailsTextView.text = details;
}

@end
