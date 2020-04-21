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
@property(weak, nonatomic) IBOutlet UIImageView *contentImage;
@property(weak, nonatomic) IBOutlet UIButton *clearImageButton;
@property(weak, nonatomic) IBOutlet UIView *actionDataContainer;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *actionDataHeight;
@property(weak, nonatomic) IBOutlet UIPickerView *actionTypePicker;

@property(nonatomic, strong) UIToolbar *keyboardToolbar;
@property(nonatomic) NSData *contentVideo;

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

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
    self.contentImage.hidden = YES;
    self.clearImageButton.hidden = YES;
    self.actionTypePicker.delegate = self;
    for (UITextField *view in @[ self.contentText, self.buttonTitle ])
    {
        view.inputAccessoryView = self.keyboardToolbar;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    if (self.activityToUpdate != nil) {
        // prefill data
        self.contentText.text = self.activityToUpdate.text;
        GetSocialActivityButton* button = self.activityToUpdate.button;
        if (button != nil) {
            self.buttonTitle.text = self.activityToUpdate.button.title;
            [button.action.data enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * value, BOOL * _Nonnull stop) {
                [self addActionData:nil];
                UIView* row = self.actionDataContainer.subviews.lastObject;
                UITextField *keyField = row.subviews[0];
                UITextField *valueField = row.subviews[1];
                keyField.text = key;
                valueField.text = value;
            }];
            // FIXME: set selected action
        }
        if (self.activityToUpdate.mediaAttachments.count != 0) {
            GetSocialMediaAttachment* firstAttachment = self.activityToUpdate.mediaAttachments.firstObject;
            NSString* mediaURL;
            if (firstAttachment.videoUrl != nil) {
                mediaURL = firstAttachment.videoUrl;
            } else {
                mediaURL = firstAttachment.imageUrl;
            }
            UIImage* downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString: mediaURL]]];
            self.contentImage.image = downloadedImage;
            self.contentImage.hidden = NO;
            self.clearImageButton.hidden = NO;
        }
    }
    [super viewWillAppear:animated];
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

- (NSDictionary<NSString*, NSArray<NSString *> *> *)actionKeyPlaceholders
{
    return @{
        GetSocialActionType.OpenUrl : @[ GetSocialActionDataKey.OpenActivity_ActivityId ],
        GetSocialActionType.OpenProfile : @[ GetSocialActionDataKey.OpenProfile_UserId ],
        GetSocialActionType.OpenActivity : @[
            GetSocialActionDataKey.OpenActivity_TopicId, GetSocialActionDataKey.OpenActivity_ActivityId,
            GetSocialActionDataKey.OpenActivity_CommentId
        ]
    };
}

- (void)addPlaceholderKey:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSInteger selectedRow = [self.actionTypePicker selectedRowInComponent:0];
        NSString *selectedItem = [self pickerView:self.actionTypePicker titleForRow:selectedRow forComponent:0];
        NSString* selectedAction = self.actions[selectedItem];
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

- (void) callUpdateActivity
{
    GetSocialActivityContent* content = [self createActivityContent];
    if (content == nil) {
        return;
    }
    [self showActivityIndicatorView];
    [GetSocialCommunities updateActivityWithId:self.activityToUpdate.activityId content:content success:^(GetSocialActivity * newActivity) {
        [self hideActivityIndicatorView];
    } failure:^(NSError * error) {
        [self hideActivityIndicatorView];
        [self showAlertWithTitle:@"Error" andText:error.localizedDescription];
    }];
}

- (GetSocialActivityContent*)createActivityContent
{
    GetSocialActivityContent *content = [GetSocialActivityContent new];
    NSString *text = self.contentText.text;
    BOOL hasText = text.length > 0;

    NSString *buttonTitle = self.buttonTitle.text;

    NSInteger selectedRow = [self.actionTypePicker selectedRowInComponent:0];
    NSString *selectedItem = [self pickerView:self.actionTypePicker titleForRow:selectedRow forComponent:0];
    NSString* selectedAction = self.actions[selectedItem];

    BOOL hasButton = buttonTitle.length > 0 || ![selectedAction isEqualToString:@"DEFAULT"];

    UIImage *image = self.contentImage.image;
    BOOL hasImage = image != nil;
    BOOL hasVideo = self.contentVideo != nil;

    if (!hasText && !hasButton && !hasImage && !hasVideo)
    {
        [self showAlertWithTitle:@"Error" andText:@"Can not post activity without any data"];
        return nil;
    }
    if (hasText)
    {
        content.text = text;
    }
    if (hasImage)
    {
        content.attachments = @[[GetSocialMediaAttachment withImage:image]];
    }
    if (hasButton)
    {
        if (![selectedAction isEqualToString:@"DEFAULT"])
        {
            GetSocialAction* action = [GetSocialAction actionWithType:selectedAction];
            [action addData:[self createActionData]];
            GetSocialActivityButton* button = [GetSocialActivityButton createWithTitle:buttonTitle action: action];
            [content setButton:button];
        }
    }

    if (hasVideo)
    {
        content.attachments = @[[GetSocialMediaAttachment withVideo:_contentVideo]];
    }

    return content;
}

- (IBAction)postActivity:(id)sender
{
    if (self.activityToUpdate != nil) {
        [self callUpdateActivity];
        return;
    }
    GetSocialActivityContent* content = [self createActivityContent];
    if (content == nil) {
        return;
    }
    [self showActivityIndicatorView];

    GetSocialActivitiesQuery* query = [GetSocialActivitiesQuery inTopicWithId:self.postTarget.targetId];
    GetSocialUIActivityFeedView *view = [GetSocialFeedsUI createActivityFeedView:query];
    __weak typeof(self) weakSelf = self;

    [view setActionHandler:^BOOL(GetSocialAction *_Nonnull action) {
        typeof(weakSelf) strongSelf = weakSelf;
        MainViewController *mainVC = (MainViewController *)strongSelf.parentViewController.parentViewController;
        return [mainVC handleAction:action];
    }];

    id onSuccess = ^(id result) {
        typeof(weakSelf) strongSelf = self;
        [strongSelf hideActivityIndicatorView];
        [view show];
    };
    id onFailure = ^(NSError *error) {
        typeof(weakSelf) strongSelf = self;
        [strongSelf hideActivityIndicatorView];
        [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
    };

    [GetSocialCommunities postActivityContent: content target:self.postTarget success: onSuccess failure: onFailure];
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

- (NSDictionary *)actions
{
    return @{
        @"Default" : @"DEFAULT",
        @"Custom" : GetSocialActionType.Custom,
        @"Open Activity" : GetSocialActionType.OpenActivity,
        @"Open Invites" : GetSocialActionType.OpenInvites,
        @"Open Profile" : GetSocialActionType.OpenProfile,
        @"Open URL" : GetSocialActionType.OpenUrl,
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
    [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%li)-[row(28)]", offset]
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
