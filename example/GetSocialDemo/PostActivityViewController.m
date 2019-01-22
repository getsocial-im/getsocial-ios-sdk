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

#import "PostActivityViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <GetSocial/GetSocial.h>
#import <GetSocialUI/GetSocialUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ConsoleViewController.h"
#import "MainViewController.h"
#import "UIImage+GetSocial.h"
#import "UISimpleAlertViewController.h"
#import "UIViewController+GetSocial.h"

#define GLOBAL_FEED @"Global Feed"
#define CUSTOM_FEED @"Custom Feed"

#define MAX_WIDTH 1024.f
#define MAX_HEIGHT 768.f

#define GSLogInfo(bShowAlert, bShowConsole, sMessage, ...) \
    [self log:LogLevelInfo context:NSStringFromSelector(_cmd) message:[NSString stringWithFormat:(sMessage), ##__VA_ARGS__] showAlert:bShowAlert]

@interface PostActivityViewController ()<UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate,
                                         UIImagePickerControllerDelegate>
{
    BOOL keyboardIsShown;
}

@property(weak, nonatomic) IBOutlet UITextView *contentText;
@property(weak, nonatomic) IBOutlet UITextField *buttonTitle;
@property(weak, nonatomic) IBOutlet UITextField *buttonAction;
@property(weak, nonatomic) IBOutlet UIImageView *contentImage;
@property(weak, nonatomic) IBOutlet UIPickerView *currentFeed;
@property(weak, nonatomic) IBOutlet UIButton *clearImageButton;
@property(weak, nonatomic) IBOutlet UIView *actionDataContainer;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *actionDataHeight;
@property(weak, nonatomic) IBOutlet UIPickerView *actionTypePicker;

@property(nonatomic, strong) UIToolbar *keyboardToolbar;
@property(nonatomic) NSData *contentVideo;

@property(nonatomic, strong) NSString *currentFeedTitle;
@property(nonatomic, strong) UIImagePickerController *imagePicker;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation PostActivityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
    keyboardIsShown = NO;

    self.currentFeed.delegate = self;
    self.currentFeed.dataSource = self;
    self.currentFeedTitle = GLOBAL_FEED;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
    self.contentImage.hidden = YES;
    self.clearImageButton.hidden = YES;
    self.actionTypePicker.delegate = self;
    for (UITextField *view in @[ self.contentText, self.buttonAction, self.buttonTitle ])
    {
        view.inputAccessoryView = self.keyboardToolbar;
    }
}

- (UIToolbar *)keyboardToolbar
{
    if (!_keyboardToolbar)
    {
        _keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        _keyboardToolbar.items =
            @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard)] ];
    }
    return _keyboardToolbar;
}

- (void)closeKeyboard
{
    [self.view endEditing:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.scrollView.contentInset =
        UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, 0, self.scrollView.contentInset.bottom);
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, keyboardSize.height,
                                                    self.scrollView.contentInset.bottom);

    keyboardIsShown = NO;
}

- (NSDictionary<NSNumber *, NSArray<NSString *> *> *)actionKeyPlaceholders
{
    return @{
        GetSocialActionOpenUrl : @[ GetSocialActionDataKey_OpenUrl_Url ],
        GetSocialActionOpenProfile : @[ GetSocialActionDataKey_OpenProfile_UserId ],
        GetSocialActionOpenActivity : @[
            GetSocialActionDataKey_OpenActivity_FeedName, GetSocialActionDataKey_OpenActivity_ActivityId,
            GetSocialActionDataKey_OpenActivity_CommentId
        ]
    };
}

- (void)addPlaceholderKey:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSInteger selectedRow = [self.actionTypePicker selectedRowInComponent:0];
        NSString *selectedItem = [self pickerView:self.actionTypePicker titleForRow:selectedRow forComponent:0];
        GetSocialActionType selectedAction = self.actions[selectedItem];
        NSArray *placeholders = self.actionKeyPlaceholders[selectedAction];
        if (!placeholders)
        {
            return;
        }

        UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Add Placeholders"
                                                                                        message:@"Choose the placeholder to add"
                                                                              cancelButtonTitle:@"Cancel"
                                                                              otherButtonTitles:placeholders];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                UITextField *textField = (UITextField *)sender.view;
                textField.text = placeholders[selectedIndex];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)postActivity:(id)sender
{
    GetSocialActivityPostContent *content = [GetSocialActivityPostContent new];
    NSString *text = self.contentText.text;
    BOOL hasText = text.length > 0;

    NSString *buttonTitle = self.buttonTitle.text;
    NSString *buttonAction = self.buttonAction.text;

    NSInteger selectedRow = [self.actionTypePicker selectedRowInComponent:0];
    NSString *selectedItem = [self pickerView:self.actionTypePicker titleForRow:selectedRow forComponent:0];
    GetSocialActionType selectedAction = self.actions[selectedItem];

    BOOL hasButton = buttonTitle.length > 0 && (buttonAction.length > 0 || ![selectedAction isEqualToString:@"DEFAULT"]);

    UIImage *image = self.contentImage.image;
    BOOL hasImage = image != nil;
    BOOL hasVideo = self.contentVideo != nil;

    BOOL globalFeed = [self.currentFeedTitle isEqualToString:GLOBAL_FEED];
    if (globalFeed && [GetSocialUser isAnonymous])
    {
        [self.delegate authorizeWithSuccess:^{
            [self postActivity:sender];
        }];
        return;
    }

    if (!hasText && !hasButton && !hasImage && !hasVideo)
    {
        [self showAlertWithTitle:@"Error" andText:@"Can not post activity without any data"];
        return;
    }
    if (hasText)
    {
        content.text = text;
    }
    if (hasImage)
    {
        content.mediaAttachment = [GetSocialMediaAttachment image:image];
    }
    if (hasButton)
    {
        content.buttonTitle = buttonTitle;
        content.buttonAction = buttonAction;
        if (![selectedAction isEqualToString:@"DEFAULT"])
        {
            GetSocialActionType actionType = (GetSocialActionType)selectedAction;
            GetSocialActionBuilder *builder = [[GetSocialActionBuilder alloc] initWithType:actionType];
            [builder addActionData:[self createActionData]];

            [content setAction:builder.build];
        }
    }

    if (hasVideo)
    {
        content.mediaAttachment = [GetSocialMediaAttachment video:_contentVideo];
    }

    [self showActivityIndicatorView];

    GetSocialUIActivityFeedView *view;

    if (globalFeed)
    {
        view = [GetSocialUI createGlobalActivityFeedView];
    }
    else
    {
        view = [GetSocialUI createActivityFeedView:@"DemoFeed"];
    }
    __weak typeof(self) weakSelf = self;

    [view setActionButtonHandler:^(NSString *action, GetSocialActivityPost *post) {
        typeof(weakSelf) strongSelf = weakSelf;
        MainViewController *mainVC = (MainViewController *)strongSelf.parentViewController.parentViewController;
        [mainVC handleAction:action withPost:post];
    }];
    [view setActionHandler:^BOOL(GetSocialAction *_Nonnull action) {
        typeof(weakSelf) strongSelf = weakSelf;
        MainViewController *mainVC = (MainViewController *)strongSelf.parentViewController.parentViewController;
        return [mainVC handleAction:action];
    }];

    GetSocialActivityResultCallback onSuccess = ^(id result) {
        typeof(weakSelf) strongSelf = self;
        [strongSelf hideActivityIndicatorView];
        [view show];
    };
    GetSocialFailureCallback onFailure = ^(NSError *error) {
        typeof(weakSelf) strongSelf = self;
        [strongSelf hideActivityIndicatorView];
        [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
    };

    if (globalFeed)
    {
        [GetSocial postActivityToGlobalFeed:content success:onSuccess failure:onFailure];
    }
    else
    {
        [GetSocial postActivity:content toFeed:@"DemoFeed" success:onSuccess failure:onFailure];
    }
}
- (IBAction)changeVideo:(id)sender
{
    [self showImagePickerViewForMediaType:(NSString *)kUTTypeMovie];
}

- (IBAction)changeImage:(id)sender
{
    [self showImagePickerViewForMediaType:(NSString *)kUTTypeImage];
}

- (void)showImagePickerViewForMediaType:(NSString *)mediaType
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.mediaTypes = @[ mediaType ];

    self.imagePicker.delegate = self;

    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)clearImage:(id)sender
{
    self.contentImage.image = nil;
    self.contentImage.hidden = YES;
    self.clearImageButton.hidden = YES;
    self.contentVideo = nil;
}

- (NSArray *)feeds
{
    return @[ GLOBAL_FEED, CUSTOM_FEED ];
}

- (NSDictionary *)actions
{
    return @{
        @"Default" : @"DEFAULT",
        @"Custom" : GetSocialActionCustom,
        @"Open Activity" : GetSocialActionOpenActivity,
        @"Open Invites" : GetSocialActionOpenInvites,
        @"Open Profile" : GetSocialActionOpenProfile,
        @"Open URL" : GetSocialActionOpenUrl,
    };
}

// clang-format off
- (NSDictionary *)pickersSetup
{
    return @{
             @(self.actionTypePicker.hash) : @{
                     @"titles" : [self.actions.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                         return [self.actions[obj1] compare:self.actions[obj2]];
                    }]
                },
             @(self.currentFeed.hash) : @{
                     @"titles" : self.feeds,
                     @"onChange" : ^(int row) {
                         self.currentFeedTitle = self.feeds[row];
                     }
                }
             };
}
// clang-format on

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.pickersSetup[@(pickerView.hash)][@"titles"] count];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    void (^onChange)(NSInteger) = self.pickersSetup[@(pickerView.hash)][@"onChange"];
    if (onChange)
    {
        onChange(row);
    }
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.pickersSetup[@(pickerView.hash)][@"titles"][row];
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        image = [image imageByResizeAndKeepRatio:CGSizeMake(MAX_WIDTH, MAX_HEIGHT)];

        self.contentImage.image = image;
    }
    else
    {
        NSURL *videoUrl = info[UIImagePickerControllerMediaURL];
        self.contentVideo = [NSData dataWithContentsOfURL:videoUrl];
        UIImage *image = [self generateThumbnailImage:videoUrl];
        int max_width = self.view.bounds.size.width * 0.8;
        image = [image imageByResizeAndKeepRatio:CGSizeMake(max_width, max_width * 0.4)];

        self.contentImage.image = image;
    }

    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;

    self.contentImage.hidden = NO;
    self.clearImageButton.hidden = NO;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;
}

- (UIImage *)generateThumbnailImage:(NSURL *)filepath
{
    AVAsset *asset = [AVAsset assetWithURL:filepath];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return thumbnail;
}

typedef NS_ENUM(NSInteger, DynamicRowType) { TemplateData, NotificationData, UserIds };

static NSInteger const DynamicRowHeight = 36;

- (IBAction)addActionData:(id)sender
{
    UIView *row = [self addDynamicRowType:NotificationData];
    UIView *key = row.subviews[0];

    UIGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPlaceholderKey:)];
    [key addGestureRecognizer:longTap];
}

- (NSDictionary *)dynamicRowTypes
{
    return @{
        @(NotificationData) : @{@"inputs" : @[ @"Key", @"Value" ], @"container" : self.actionDataContainer, @"constraint" : self.actionDataHeight}
    };
}

- (UIView *)addDynamicRowType:(DynamicRowType)type
{
    UIView *container = self.dynamicRowTypes[@(type)][@"container"];
    NSArray *inputs = self.dynamicRowTypes[@(type)][@"inputs"];
    NSLayoutConstraint *heightConstraint = self.dynamicRowTypes[@(type)][@"constraint"];
    NSInteger numberOfRow = container.subviews.count;

    UIView *row = [UIView new];
    row.tag = numberOfRow;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableString *constraint = [@"H:|" mutableCopy];
    NSMutableDictionary *views = [@{} mutableCopy];

    [inputs enumerateObjectsUsingBlock:^(NSString *input, NSUInteger idx, BOOL *stop) {
        UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 21)];

        field.accessibilityIdentifier = input;
        field.inputAccessoryView = self.keyboardToolbar;
        field.userInteractionEnabled = YES;
        field.placeholder = input;
        field.borderStyle = UITextBorderStyleRoundedRect;
        field.translatesAutoresizingMaskIntoConstraints = NO;

        [row addSubview:field];
        [constraint appendFormat:@"-[%@(100)]", input.lowercaseString];
        views[input.lowercaseString] = field;
    }];

    UIButton *remove = [UIButton buttonWithType:UIButtonTypeSystem];
    remove.tag = type;
    remove.translatesAutoresizingMaskIntoConstraints = NO;
    [remove setTitle:@"Remove" forState:UIControlStateNormal];
    [remove addTarget:self action:@selector(removeDynamicRow:) forControlEvents:UIControlEventTouchUpInside];
    [remove sizeToFit];
    [row addSubview:remove];
    [constraint appendString:@"-(>=40@250)-[remove(60)]-|"];
    views[@"remove"] = remove;

    [row addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraint options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];

    [row addConstraint:[NSLayoutConstraint constraintWithItem:row.subviews[0]
                                                    attribute:NSLayoutAttributeCenterY
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:row
                                                    attribute:NSLayoutAttributeCenterY
                                                   multiplier:1
                                                     constant:0]];

    [container addSubview:row];
    [container addConstraint:[NSLayoutConstraint constraintWithItem:row
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:container
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:0]];
    NSInteger offset = numberOfRow * DynamicRowHeight + 8;
    [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%i)-[row(28)]", offset]
                                                                      options:NSLayoutFormatDirectionLeftToRight
                                                                      metrics:nil
                                                                        views:@{@"row" : row}]];
    heightConstraint.constant += DynamicRowHeight;

    return row;
}

- (void)removeDynamicRow:(UIButton *)sender
{
    DynamicRowType type = (DynamicRowType)sender.tag;
    UIView *container = self.dynamicRowTypes[@(type)][@"container"];
    NSLayoutConstraint *heightConstraint = self.dynamicRowTypes[@(type)][@"constraint"];

    UIView *row = sender.superview;
    NSInteger deletedRow = row.tag;
    [container.constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        if (constraint.firstItem == row || constraint.secondItem == row)
        {
            [container removeConstraint:constraint];
        }
        else if (constraint.firstAttribute == NSLayoutAttributeTop)
        {
            UIView *anotherRow = constraint.firstItem;
            if (anotherRow.tag > deletedRow)
            {
                anotherRow.tag -= 1;
                constraint.constant -= DynamicRowHeight;
            }
        }
    }];
    heightConstraint.constant -= DynamicRowHeight;
    [row removeFromSuperview];
}

- (NSDictionary *)createActionData
{
    NSMutableDictionary *actionData = [NSMutableDictionary new];
    [self.actionDataContainer.subviews enumerateObjectsUsingBlock:^(__kindof UIView *row, NSUInteger idx, BOOL *stop) {
        UITextField *key = row.subviews[0];
        UITextField *val = row.subviews[1];
        actionData[key.text] = val.text;
    }];
    return actionData;
}

@end
