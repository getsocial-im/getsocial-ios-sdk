/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "UserViewController.h"
#import "UserIdentityViewController.h"

@interface UserViewController ()
@property(weak, nonatomic) IBOutlet UITextView *detailsTextView;

@end

@implementation UserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [[NSNotificationCenter defaultCenter] addObserverForName:GetSocialUserIdentityUpdatedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {

                                                      [self updateUserDetails];
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
    GetSocialUserIdentity *userIdentity = [GetSocial sharedInstance].loggedInUser;

    if (userIdentity)
    {
        NSMutableString *details = [NSMutableString string];

        [details appendFormat:@"DisplayName: %@\n", userIdentity.displayName];
        [details appendFormat:@"Guid: %@\n", userIdentity.guid];
        [details appendFormat:@"Avatar: %@\n", userIdentity.avatarUrl];

        [details appendString:@"\n\nIdentities\n\n"];

        [userIdentity.identities enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [details appendFormat:@"Provider: %@\n", key];
            [details appendFormat:@"UserId: %@\n", obj];
            [details appendString:@"\n\n"];
        }];

        self.detailsTextView.text = details;
    }
    else
    {
        self.detailsTextView.text = @"";
    }
}

@end
