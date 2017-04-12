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

#import "CustomSmartInviteViewController.h"
#import <GetSocial/GetSocial.h>
#import <GetSocialUI/GetSocialUI.h>
#import "UISimpleAlertViewController.h"

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

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // resize the scrollview
    CGRect viewFrame = self.scrollView.frame;
    viewFrame.size.height += keyboardSize.height;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.scrollView setFrame:viewFrame];
    [UIView commitAnimations];

    keyboardIsShown = NO;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (keyboardIsShown)
    {
        return;
    }

    NSDictionary *userInfo = [notification userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

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
                          GetSocial_InviteContentPlaceholder_App_Invite_Url
                          ];

        UISimpleAlertViewController *alert =
            [[UISimpleAlertViewController alloc] initWithTitle:@"Add Tag" message:@"Choose the tag to add" cancelButtonTitle:@"Cancel" otherButtonTitles:tags];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                UITextField *textField = (UITextField *) sender.view;
                textField.text = [textField.text stringByAppendingString:tags[selectedIndex - 1]];
            }
        } onViewController:self];
    }
}

- (IBAction)onOpenSmartInvite:(id)sender
{
    [self.view endEditing:YES];

    GetSocialMutableInviteContent* mutableInviteContent = [GetSocialMutableInviteContent new];

    if (![self.textfield.text isEqualToString:@""])
    {
        mutableInviteContent.text = self.textfield.text;
    }

    if (![self.subjectField.text isEqualToString:@""])
    {
        mutableInviteContent.subject = self.subjectField.text;
    }

    NSMutableDictionary* customReferralData = [NSMutableDictionary new];
    if (![self.key1Field.text isEqualToString:@""] && ![self.value1Field.text isEqualToString:@""])
    {
        customReferralData[self.key1Field.text] = self.value1Field.text;
    }

    if (![self.key2Field.text isEqualToString:@""] && ![self.value2Field.text isEqualToString:@""])
    {
        customReferralData[self.key2Field.text] = self.value3Field.text;
    }

    if (![self.key3Field.text isEqualToString:@""] && ![self.value3Field.text isEqualToString:@""])
    {
        customReferralData[self.key3Field.text] = self.value3Field.text;
    }

    GetSocialUIInvitesView* invitesView = [GetSocialUI createInvitesView];
    [invitesView setCustomInviteContent:mutableInviteContent];
    [invitesView setCustomReferralData:customReferralData];

    if ([self.textfield.text rangeOfString:GetSocial_InviteContentPlaceholder_App_Invite_Url].location == NSNotFound)
    {
        UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Send Smart Invite"
                                                          message:@"No placeholder for URL found in text, would you like to continue "
                                                                  @"anyway?\nWithout placeholder the invite URL will not be visible."
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@[ @"Ok" ]];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                [invitesView show];
            }
        } onViewController:self];
    }
    else
    {
        [invitesView show];
    }
}

- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

@end
