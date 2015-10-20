/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

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

    [[NSNotificationCenter defaultCenter] addObserverForName:GetSocialUserIdentityUpdatedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {

                                                      [self updateUserDetails];
                                                  }];
    
    [self updateUserDetails];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateUserDetails];
}

- (void)updateUserDetails
{
    GetSocialUserIdentity *userIdentity = [GetSocial sharedInstance].loggedInUser;

    if (userIdentity)
    {
        __block NSString *identities = @"";
        
        [userIdentity.identities enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            identities = [identities stringByAppendingFormat:@"%@, ", key];
        }];

        identities = [identities stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL URLWithString:userIdentity.avatarUrl];

            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage imageWithData:data];

            dispatch_async(dispatch_get_main_queue(), ^(void) {

                [UIView transitionWithView:self.avatarImageView
                                  duration:.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [self.avatarImageView setImage:image];
                                    self.displayNameLabel.text = userIdentity.displayName;
                                    self.identitiesLabel.text = identities;
                                }
                                completion:nil];
            });
        });
    }
    else
    {
        [UIView transitionWithView:self.avatarImageView
                          duration:.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.displayNameLabel.text = @"User not logged in";
                            self.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar"];
                            self.identitiesLabel.text = @"";
                        }
                        completion:nil];
    }
}


@end
