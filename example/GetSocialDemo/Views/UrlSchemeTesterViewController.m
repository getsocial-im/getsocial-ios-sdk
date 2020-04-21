//
//  UrlSchemeTesterViewController.m
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "UrlSchemeTesterViewController.h"
#import "UISimpleAlertViewController.h"

@interface UrlSchemeTesterViewController ()

@property(weak, nonatomic) IBOutlet UITextField *urlInput;

@end

@implementation UrlSchemeTesterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)generateUrl:(id)sender
{
    BOOL result = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.urlInput.text]];
    if (!result)
    {
        [[[UISimpleAlertViewController alloc] initWithTitle:@"Error"
                                                    message:@"Failed to open the URL."
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil] showWithDismissHandler:nil];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
