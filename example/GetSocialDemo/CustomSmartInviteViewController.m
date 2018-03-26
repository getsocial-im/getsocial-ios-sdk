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
#import "UIImage+GetSocial.h"
#import "UISimpleAlertViewController.h"

#define MAX_WIDTH 1024.f
#define MAX_HEIGHT 768.f

#define IMAGE_HEIGHT 140

#define INVITE_SECTION_HEIGHT_W_IMAGE 325
#define LP_SECTION_HEIGHT_W_IMAGE 368

@interface CustomSmartInviteViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL keyboardIsShown;
}
@property(weak, nonatomic) IBOutlet UIImageView *customImage;
@property(nonatomic, strong) UIImagePickerController *imagePicker;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *inviteSectionHeight;

@property(nonatomic) BOOL selectImageForInvite;

// landing page customization
@property(weak, nonatomic) IBOutlet UITextField *landingPageTitle;
@property(weak, nonatomic) IBOutlet UITextField *landingPageDescription;

@property(weak, nonatomic) IBOutlet UITextField *landingPageImageUrl;

@property(weak, nonatomic) IBOutlet UITextField *landingPageVideoUrl;

@property(weak, nonatomic) IBOutlet UIImageView *landingPageImage;

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *landingPageSectionHeight;

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

    self.inviteSectionHeight.constant = INVITE_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
    self.landingPageSectionHeight.constant = LP_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        NSArray *tags = @[ GetSocial_InviteContentPlaceholder_App_Invite_Url ];

        UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Add Tag"
                                                                                        message:@"Choose the tag to add"
                                                                              cancelButtonTitle:@"Cancel"
                                                                              otherButtonTitles:tags];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                UITextField *textField = (UITextField *)sender.view;
                textField.text = [textField.text stringByAppendingString:tags[selectedIndex]];
            }
        }];
    }
}

- (IBAction)onOpenSmartInvite:(id)sender
{
    [self.view endEditing:YES];

    GetSocialMutableInviteContent *mutableInviteContent = [GetSocialMutableInviteContent new];

    if (![self.textfield.text isEqualToString:@""])
    {
        mutableInviteContent.text = self.textfield.text;
    }

    if (![self.subjectField.text isEqualToString:@""])
    {
        mutableInviteContent.subject = self.subjectField.text;
    }
    if (self.customImage.image)
    {
        mutableInviteContent.image = self.customImage.image;
    }

    GetSocialUIInvitesView *invitesView = [GetSocialUI createInvitesView];
    [invitesView setCustomInviteContent:mutableInviteContent];
    [invitesView setLinkParams:[self addLandingPageCustomization]];

    if ([self.textfield.text rangeOfString:GetSocial_InviteContentPlaceholder_App_Invite_Url].location == NSNotFound)
    {
        UISimpleAlertViewController *alert =
            [[UISimpleAlertViewController alloc] initWithTitle:@"Send Smart Invite"
                                                       message:
                                                           @"No placeholder for URL found in text, would you like to continue "
                                                           @"anyway?\nWithout placeholder the invite URL will not be visible."
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:@[ @"Ok" ]];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                [invitesView show];
            }
        }];
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

- (IBAction)changeImage:(id)sender
{
    self.selectImageForInvite = YES;
    [self openImagePicker];
}

- (IBAction)clearImage:(id)sender
{
    if (self.customImage.image == self.landingPageImage.image)
    {
        self.landingPageImage.image = nil;
        self.landingPageSectionHeight.constant = LP_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
    }
    self.customImage.image = nil;
    self.inviteSectionHeight.constant = INVITE_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
}

- (IBAction)changeLandingPageImage:(id)sender
{
    self.selectImageForInvite = NO;
    [self openImagePicker];
}

- (IBAction)clearLandingPageImage:(id)sender
{
    self.landingPageImage.image = nil;
    self.landingPageSectionHeight.constant = LP_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
}

- (IBAction)useSameImage:(id)sender
{
    if (self.customImage.image != nil)
    {
        self.landingPageImage.image = self.customImage.image;
        self.landingPageSectionHeight.constant = LP_SECTION_HEIGHT_W_IMAGE;
    }
}

- (NSMutableDictionary *)addLandingPageCustomization
{
    NSMutableDictionary *linkParams = [NSMutableDictionary new];

    // add custom title
    if (self.landingPageTitle.text.length > 0)
    {
        linkParams[GetSocial_Custom_Title] = self.landingPageTitle.text;
    }
    // add custom description
    if (self.landingPageDescription.text.length > 0)
    {
        linkParams[GetSocial_Custom_Description] = self.landingPageDescription.text;
    }
    // add custom image url
    if (self.landingPageImageUrl.text.length > 0)
    {
        linkParams[GetSocial_Custom_Image] = self.landingPageImageUrl.text;
    }
    // add custom video url
    if (self.landingPageVideoUrl.text.length > 0)
    {
        linkParams[GetSocial_Custom_YouTubeVideo] = self.landingPageVideoUrl.text;
    }
    // add custom image
    if (self.landingPageImage.image != nil)
    {
        linkParams[GetSocial_Custom_Image] = self.landingPageImage.image;
    }
    // add other properties
    if (![self.key1Field.text isEqualToString:@""] && ![self.value1Field.text isEqualToString:@""])
    {
        linkParams[self.key1Field.text] = self.value1Field.text;
    }

    if (![self.key2Field.text isEqualToString:@""] && ![self.value2Field.text isEqualToString:@""])
    {
        linkParams[self.key2Field.text] = self.value2Field.text;
    }

    if (![self.key3Field.text isEqualToString:@""] && ![self.value3Field.text isEqualToString:@""])
    {
        linkParams[self.key3Field.text] = self.value3Field.text;
    }
    return linkParams;
}

- (void)openImagePicker
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.delegate = self;

    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    image = [image imageByResizeAndKeepRatio:CGSizeMake(MAX_WIDTH, MAX_HEIGHT)];

    if (self.selectImageForInvite)
    {
        self.customImage.image = image;
        self.inviteSectionHeight.constant = INVITE_SECTION_HEIGHT_W_IMAGE;
    }
    else
    {
        self.landingPageImage.image = image;
        self.landingPageSectionHeight.constant = LP_SECTION_HEIGHT_W_IMAGE;
    }

    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;

    if (self.selectImageForInvite)
    {
        self.inviteSectionHeight.constant = INVITE_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
    }
    else
    {
        self.landingPageSectionHeight.constant = LP_SECTION_HEIGHT_W_IMAGE - IMAGE_HEIGHT;
    }
}

@end
