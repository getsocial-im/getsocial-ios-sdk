/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "CustomSmartInviteViewController.h"
#import <GetSocial/GetSocial.h>
#import "UIBAlertView.h"

@interface CustomSmartInviteViewController ()
{
    BOOL keyboardIsShown;
}

@end

@implementation CustomSmartInviteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
    keyboardIsShown = NO;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGSize scrollContentSize = CGSizeMake(320, self.closeButton.frame.origin.y + self.closeButton.frame.size.height);
    self.scrollView.contentSize = scrollContentSize;
}

- (void)keyboardWillHide:(NSNotification *)n
{
    NSDictionary *userInfo = [n userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // resize the scrollview
    CGRect viewFrame = self.scrollView.frame;
    viewFrame.size.height += keyboardSize.height;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.scrollView setFrame:viewFrame];
    [UIView commitAnimations];

    keyboardIsShown = NO;
}

- (void)keyboardWillShow:(NSNotification *)n
{
    if (keyboardIsShown)
    {
        return;
    }

    NSDictionary *userInfo = [n userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // resize the noteView
    CGRect viewFrame = self.scrollView.frame;
    viewFrame.size.height -= keyboardSize.height;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.scrollView setFrame:viewFrame];
    [UIView commitAnimations];
    keyboardIsShown = YES;
}

- (IBAction)addTag:(UIGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        NSArray *tags = @[
            kGetSocialAppInviteUrlPlaceholder,
            kGetSocialAppNamePlaceholder,
            kGetSocialUserDisplayNamePlaceholder,
            kGetSocialAppIconUrlPlaceholder,
            kGetSocialAppInviteUrlPlaceholder
        ];

        UIBAlertView *alert =
            [[UIBAlertView alloc] initWithTitle:@"Add Tag" message:@"Choose the tag to add" cancelButtonTitle:@"Cancel" otherButtonTitles:tags];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                UITextField *textField = (UITextField *)((UIGestureRecognizer *)sender).view;
                textField.text = [textField.text stringByAppendingString:tags[selectedIndex - 1]];
            }
        }];
    }
}

- (IBAction)onClose:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onOpenSmartInvite:(id)sender
{
    [self.view endEditing:YES];

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    NSMutableDictionary *referralData = [NSMutableDictionary dictionary];

    properties[@"1"] = @{ @"level" : @1, @"stars" : @20, @"reward" : @YES, @"source" : @"topRightButton" };

    GetSocialSmartInviteViewBuilder *viewBuilder = [[GetSocial sharedInstance] createSmartInviteView];

    if (![self.textfield.text isEqualToString:@""])
    {
        viewBuilder.text = self.textfield.text;
    }

    if (![self.subjectField.text isEqualToString:@""])
    {
        viewBuilder.subject = self.subjectField.text;
    }

    if (![self.key1Field.text isEqualToString:@""] && ![self.value1Field.text isEqualToString:@""])
    {
        [referralData setObject:self.value1Field.text forKey:self.key1Field.text];
    }

    if (![self.key2Field.text isEqualToString:@""] && ![self.value2Field.text isEqualToString:@""])
    {
        [referralData setObject:self.value3Field.text forKey:self.key2Field.text];
    }

    if (![self.key3Field.text isEqualToString:@""] && ![self.value3Field.text isEqualToString:@""])
    {
        [referralData setObject:self.value3Field.text forKey:self.key3Field.text];
    }

    viewBuilder.referralData = referralData;

    if ([self.textfield.text rangeOfString:kGetSocialAppInviteUrlPlaceholder].location == NSNotFound)
    {
        UIBAlertView *alert = [[UIBAlertView alloc] initWithTitle:@"Send Smart Invite"
                                                          message:@"No placeholder for URL found in text, would you like to continue "
                                                          @"anyway?\nWithout placeholder the invite URL will not be visible."
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@[ @"Ok" ]];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                [viewBuilder show];
            }
        }];
    }
    else
    {
        [viewBuilder show];
    }
}

- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

@end
