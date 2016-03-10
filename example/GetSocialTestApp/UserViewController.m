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
    GetSocialCurrentUser *user = [GetSocial sharedInstance].currentUser;

    if (user)
    {
        NSMutableString *details = [NSMutableString string];

        [details appendFormat:@"DisplayName: %@\n", user.displayName];
        [details appendFormat:@"Guid: %@\n", user.guid];
        [details appendFormat:@"Avatar: %@\n", user.avatarUrl];

        if (!user.isAnonymous)
        {
            [details appendString:@"\n\nIdentities\n\n"];
            [user.identities enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [details appendFormat:@"Provider: %@\n", obj];
                [details appendFormat:@"UserId: %@\n", [user userIdForProvider:obj]];
                [details appendString:@"\n\n"];
            }];
        }
        else
        {
            [details appendString:@"\n\nAnonymous\n\n"];
        }

        self.detailsTextView.text = details;
    }
    else
    {
        self.detailsTextView.text = @"";
    }
}

@end
