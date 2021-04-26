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

#import "UserIdentityViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
#import "Constants.h"

@interface UserIdentityViewController ()

@property(weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property(weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property(weak, nonatomic) IBOutlet UILabel *identitiesLabel;
@property (weak, nonatomic) IBOutlet UIImageView *testDevice;

@end

@implementation UserIdentityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.testDevice.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserverForName:UserWasUpdatedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self updateUserDetails];
                                                      });
                                                  }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateUserDetails];
}

- (void)updateUserDetails
{
    BOOL isTestDevice = [GetSocial isTestDevice];
    self.testDevice.hidden = !isTestDevice;

    __block NSString *identities = @"";
    if (!GetSocial.currentUser.isAnonymous)
    {
        [GetSocial.currentUser.identities enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
            identities = [identities stringByAppendingFormat:@"%@, ", key];
        }];
        identities = [identities stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
    }
    else
    {
        identities = @"Anonymous";
    }

    NSString *displayName = GetSocial.currentUser.displayName;
    if (displayName.length == 0)
    {
        displayName = [NSString stringWithFormat:@"id: %@", GetSocial.currentUser.userId];
    }
    self.displayNameLabel.text = displayName;
    NSString *imageURL = GetSocial.currentUser.avatarUrl;
    if (imageURL.length > 0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
            UIImage *image = [UIImage imageWithData:imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([imageURL isEqualToString:GetSocial.currentUser.avatarUrl]) {
                    self.avatarImageView.image = image;
                }
            });
        });
    }
    else
    {
        self.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar.png"];
    }
    self.identitiesLabel.text = identities;
}

@end