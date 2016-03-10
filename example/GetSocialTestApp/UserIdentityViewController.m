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

@interface UserIdentityViewController ()

@property(weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property(weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property(weak, nonatomic) IBOutlet UILabel *identitiesLabel;

@end

@implementation UserIdentityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:UserWasUpdatedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self updateUserDetails];
                                                      });
                                                  }];

    [self updateUserDetails];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateUserDetails];
}

- (void)updateUserDetails
{
    GetSocialCurrentUser *user = [GetSocial sharedInstance].currentUser;

    if (user)
    {
        __block NSString *identities = @"";

        if (!user.isAnonymous)
        {
            [user.identities enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                identities = [identities stringByAppendingFormat:@"%@, ", obj];
            }];

            identities = [identities stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        }
        else
        {
            identities = @"Anonymous";
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL URLWithString:user.avatarUrl];

            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage imageWithData:data];

            dispatch_async(dispatch_get_main_queue(), ^(void) {

                [UIView transitionWithView:self.avatarImageView
                                  duration:.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [self.avatarImageView setImage:image];
                                }
                                completion:nil];
            });
        });

        self.displayNameLabel.text = user.displayName;
        self.identitiesLabel.text = identities;
    }
    else
    {
        [UIView transitionWithView:self.avatarImageView
                          duration:.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar"];

                        }
                        completion:nil];

        self.displayNameLabel.text = @"<No user>";
        self.identitiesLabel.text = @"";
    }
}

@end
