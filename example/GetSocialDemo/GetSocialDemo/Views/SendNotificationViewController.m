//
//  SendNotificationViewController.m
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "SendNotificationViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <GetSocialSDK/GetSocialSDK.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+GetSocial.h"
#import "UISimpleAlertViewController.h"
#import "UIViewController+GetSocial.h"
#import "UITextFieldWithCopyPaste.h"

#define MAX_WIDTH 1024.f
#define MAX_HEIGHT 768.f

#define IMAGE_HEIGHT 140

#define CUSTOM_MEDIA_SECTION_HEIGHT_WITH_IMAGES 160

#define DEFAULT_ACTION @"Default"

typedef NS_ENUM(NSUInteger, ViewState) { Hidden, Selected, Visible };

@interface SendNotificationViewController ()<UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property(weak, nonatomic) IBOutlet UIView *templateContainer;
@property(weak, nonatomic) IBOutlet UIView *textContainer;

@property(weak, nonatomic) IBOutlet UITextField *templateName;
@property(weak, nonatomic) IBOutlet UIView *templateData;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *templateDataHeight;

@property(weak, nonatomic) IBOutlet UITextField *customText;
@property(weak, nonatomic) IBOutlet UITextField *customTitle;

// custom image/video controls
@property(nonatomic, strong) UIImagePickerController *imagePicker;
@property(nonatomic) NSData *customVideoContent;
@property(weak, nonatomic) IBOutlet UIButton *buttonChangeCustomImage;
@property(weak, nonatomic) IBOutlet UIButton *buttonChangeCustomVideo;
@property(weak, nonatomic) IBOutlet UIButton *buttonRemoveCustomImage;
@property(weak, nonatomic) IBOutlet UIButton *buttonRemoveCustomVideo;
@property(weak, nonatomic) IBOutlet UIImageView *customImagePreview;
@property(weak, nonatomic) IBOutlet UIImageView *customVideoPreview;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *customImageSectionHeight;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *customVideoSectionHeight;
@property(weak, nonatomic) IBOutlet UITextField *imageUrl;
@property(weak, nonatomic) IBOutlet UITextField *videoUrl;

@property(weak, nonatomic) IBOutlet UIPickerView *notificationAction;
@property(weak, nonatomic) IBOutlet UIView *actionData;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *actionDataHeight;
@property(weak, nonatomic) IBOutlet UIView *actionButtons;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *actionButtonsHeight;

@property(weak, nonatomic) IBOutlet UIView *customUserIds;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *customUserIdsHeight;

@property(nonatomic, strong, readonly) NSDictionary *pickersSetup;

@property(nonatomic, strong, readonly) NSDictionary *actions;

@property(nonatomic, strong) NSMutableArray *recipients;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property(weak, nonatomic) IBOutlet UITextField *backgroundImage;
@property(weak, nonatomic) IBOutlet UITextField *titleColor;
@property(weak, nonatomic) IBOutlet UITextField *textColor;
@property (weak, nonatomic) IBOutlet UISwitch *enableBadgeCount;
@property (weak, nonatomic) IBOutlet UISwitch *enableBadgeIncrease;
@property (weak, nonatomic) IBOutlet UITextField *badgeCount;
@property (weak, nonatomic) IBOutlet UITextField *badgeIncrease;

@end

@implementation SendNotificationViewController

typedef NS_ENUM(NSInteger, DynamicRowType) { TemplateData, NotificationData, UserIds, ActionButtons };

static NSInteger const DynamicRowHeight = 36;

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

    UIGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPlaceholder:)];
    [self.customText addGestureRecognizer:longTap];

    self.notificationAction.delegate = self;
    self.notificationAction.dataSource = self;

    self.recipients = [NSMutableArray new];

    self.templateData.translatesAutoresizingMaskIntoConstraints = NO;

    [self setVideoViewState:Visible];
    [self setImageViewState:Visible];

    self.customImageSectionHeight.constant = CUSTOM_MEDIA_SECTION_HEIGHT_WITH_IMAGES - IMAGE_HEIGHT;
    self.customVideoSectionHeight.constant = CUSTOM_MEDIA_SECTION_HEIGHT_WITH_IMAGES - IMAGE_HEIGHT;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.scrollView.contentInset =
        UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, 0, self.scrollView.contentInset.right);
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, keyboardSize.height,
                                                    self.scrollView.contentInset.right);
}

- (void)addPlaceholder:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSArray *placeholders =
            @[ GetSocialNotificationContentPlaceholders.senderDisplayName, GetSocialNotificationContentPlaceholders.receiverDisplayName ];

        UISimpleAlertViewController *alert = [[UISimpleAlertViewController alloc] initWithTitle:@"Add Placeholders"
                                                                                        message:@"Choose the placeholder to add"
                                                                              cancelButtonTitle:@"Cancel"
                                                                              otherButtonTitles:placeholders];

        [alert showWithDismissHandler:^(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel) {
            if (!didCancel)
            {
                UITextField *textField = (UITextField *)sender.view;
                textField.text = [textField.text stringByAppendingString:placeholders[selectedIndex]];
            }
        }];
    }
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)actionKeyPlaceholders
{
    return @{
        GetSocialActionType.openUrl : @[ GetSocialActionDataKey.openUrl_Url ],
        GetSocialActionType.openProfile : @[ GetSocialActionDataKey.openProfile_UserId],
        GetSocialActionType.openActivity : @[
            GetSocialActionDataKey.openActivity_TopicId, GetSocialActionDataKey.openActivity_ActivityId,
            GetSocialActionDataKey.openActivity_CommentId
        ]
    };
}

- (void)addPlaceholderKey:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSInteger selectedRow = [self.notificationAction selectedRowInComponent:0];
        NSString *selectedItem = [self pickerView:self.notificationAction titleForRow:selectedRow forComponent:0];
        NSString *selectedAction = self.actions[selectedItem];
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

- (void)addActionButtonPlaceholderKey:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSArray *placeholders =
        @[ @"custom", GetSocialActionType.openActivity, GetSocialActionType.openProfile, GetSocialActionType.openInvites, GetSocialActionType.openUrl];
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

- (IBAction)addTemplateData:(id)sender
{
    [self addDynamicRowType:TemplateData];
}

- (IBAction)addActionButton:(id)sender
{
    UIView *row = [self addDynamicRowType:ActionButtons];
    UIView *actionId = row.subviews[1];

    UIGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addActionButtonPlaceholderKey:)];
    [actionId addGestureRecognizer:longTap];
}

- (IBAction)addActionData:(id)sender
{
    UIView *row = [self addDynamicRowType:NotificationData];
    UIView *key = row.subviews[0];

    UIGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPlaceholderKey:)];
    [key addGestureRecognizer:longTap];
}

- (IBAction)toggleFriends:(UIButton *)sender
{
    [self toggleRecipient:GetSocialNotificationReceiverPlaceholders.friends withButton:sender];
}

- (IBAction)toggleReferrer:(id)sender
{
    [self toggleRecipient:GetSocialNotificationReceiverPlaceholders.referrer withButton:sender];
}

- (IBAction)toggleReferredUsers:(id)sender
{
    [self toggleRecipient:GetSocialNotificationReceiverPlaceholders.referredUsers withButton:sender];
}

- (IBAction)addCustomUserId:(id)sender
{
    [self addDynamicRowType:UserIds];
}

- (NSDictionary *)dynamicRowTypes
{
    return @{
        @(TemplateData) : @{@"inputs" : @[ @"Key", @"Value" ], @"container" : self.templateData, @"constraint" : self.templateDataHeight},
        @(NotificationData) : @{@"inputs" : @[ @"Key", @"Value" ], @"container" : self.actionData, @"constraint" : self.actionDataHeight},
        @(UserIds) : @{@"inputs" : @[ @"UserID" ], @"container" : self.customUserIds, @"constraint" : self.customUserIdsHeight},
        @(ActionButtons) : @{@"inputs" : @[ @"Title", @"ActionID" ], @"container" : self.actionButtons, @"constraint" : self.actionButtonsHeight}
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
        UITextField *field = [[UITextFieldWithCopyPaste alloc] initWithFrame:CGRectMake(0, 0, 60, 21)];

        field.accessibilityIdentifier = input;
        field.enabled = YES;
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
    long offset = numberOfRow * DynamicRowHeight + 8;
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

- (void)toggleRecipient:(NSString *)recipient withButton:(UIButton *)button
{
    BOOL shouldAdd = [@"Add" isEqualToString:button.titleLabel.text];
    NSString *newLabel = shouldAdd ? @"Remove" : @"Add";
    [button setTitle:newLabel forState:UIControlStateNormal];
    if (shouldAdd)
    {
        [self.recipients addObject:recipient];
    }
    else
    {
        [self.recipients removeObject:recipient];
    }
}

- (IBAction)sendNotification:(id)sender
{
    NSInteger selectedRow = [self.notificationAction selectedRowInComponent:0];
    NSString *selectedItem = [self pickerView:self.notificationAction titleForRow:selectedRow forComponent:0];
    NSString* selectedAction = self.actions[selectedItem];

    if (self.templateName.text.length == 0 && self.customText.text.length == 0 && [selectedAction isEqual:GetSocialActionType.addFriend])
    {
        GetSocialNotificationContent *content = [GetSocialNotificationContent
            withText:[NSString stringWithFormat:@"%@ wants to become friends", GetSocialNotificationContentPlaceholders.senderDisplayName]];
        [content setTitle:@"Friend Request"];


        NSMutableDictionary* actionData = [NSMutableDictionary new];
        [actionData setObject:GetSocial.currentUser.userId forKey: GetSocialActionDataKey.addFriend_UserId];
        [actionData setObject:GetSocial.currentUser.displayName forKey: @"user_name"];

        GetSocialAction *action = [GetSocialAction actionWithType: selectedAction data: actionData];

        [content setAction:action];
        content.actionButtons = [self createActionButtons];

        GetSocialSendNotificationTarget * target = [GetSocialSendNotificationTarget usersWithIds: [GetSocialUserIdList create: [self createUserIds]]];
        [GetSocialNotifications sendNotificationContent: content
            target: target
            success:^(void) {
                [self log:LogLevelInfo
                      context:@"Send Notification"
                  message:@"Successfully sent notifications."
                    showAlert:YES];
            }
            failure:^(NSError *error) {
                [self log:LogLevelError
                      context:@"Send Notification"
                      message:[NSString stringWithFormat:@"Failed to send notification. Error: %@.", error]
                    showAlert:YES];
            }];
        return;
    }
    GetSocialNotificationContent *content = self.templateName.text.length > 0 ? [GetSocialNotificationContent withTemplateName:self.templateName.text]
                                                                              : [GetSocialNotificationContent withText:self.customText.text];

    if (self.customTitle.text.length > 0)
    {
        [content setTitle:self.customTitle.text];
    }

    if (self.customText.text.length > 0)
    {
        [content setText:self.customText.text];
    }

    if (self.templateName.text.length > 0)
    {
        [content setTemplateName:self.templateName.text];
        content.templatePlaceholders = [self createTemplateData];
    }

    if (![DEFAULT_ACTION isEqual:selectedAction])
    {
        GetSocialAction *action = [GetSocialAction actionWithType:selectedAction data: [self createActionData]];
        [content setAction:action];
    }
    content.actionButtons = [self createActionButtons];

    GetSocialMediaAttachment *attachment =
        self.imageUrl.text.length > 0
            ? [GetSocialMediaAttachment withImageUrl:self.imageUrl.text]
            : self.videoUrl.text.length > 0 ? [GetSocialMediaAttachment withVideoUrl:self.videoUrl.text]
                                            : self.customImagePreview.image != nil
                                                  ? [GetSocialMediaAttachment withImage:self.customImagePreview.image]
                                                  : self.customVideoContent != nil ? [GetSocialMediaAttachment withVideo:self.customVideoContent] : nil;

    [content setMediaAttachment:attachment];

    // set customization
    GetSocialNotificationCustomization *customization = [GetSocialNotificationCustomization new];
    if (self.backgroundImage.text.length > 0)
    {
        [customization setBackgroundImageConfiguration:self.backgroundImage.text];
    }
    if (self.titleColor.text.length > 0)
    {
        [customization setTitleColor:self.titleColor.text];
    }
    if (self.textColor.text.length > 0)
    {
        [customization setTextColor:self.textColor.text];
    }

    if (self.enableBadgeCount.on) {
        int value = self.badgeCount.text.intValue;
        GetSocialNotificationBadge *badge = [GetSocialNotificationBadge setTo:value];
        content.badge = badge;
    } else if (self.enableBadgeIncrease.on) {
        int value = self.badgeIncrease.text.intValue;
        GetSocialNotificationBadge *badge = [GetSocialNotificationBadge increaseBy:value];
        content.badge = badge;
    }

    if (self.enableBadgeCount.on) {
        int value = self.badgeCount.text.intValue;
        GetSocialNotificationBadge *badge = [GetSocialNotificationBadge setTo:value];
        content.badge = badge;
    } else if (self.enableBadgeIncrease.on) {
        int value = self.badgeIncrease.text.intValue;
        GetSocialNotificationBadge *badge = [GetSocialNotificationBadge increaseBy:value];
        content.badge = badge;
    }

    GetSocialSendNotificationTarget * target = [GetSocialSendNotificationTarget usersWithIds: [GetSocialUserIdList create: [self createUserIds]]];

    [self showActivityIndicatorView];
    [GetSocialNotifications sendNotificationContent: content
        target:target
        success:^(void) {
            [self hideActivityIndicatorView];
            [self log:LogLevelInfo
                  context:@"Send Notification"
              message:@"Successfully sent notifications."
                showAlert:YES];
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            [self log:LogLevelError
                  context:@"Send Notification"
                  message:[NSString stringWithFormat:@"Failed to send notification. Error: %@.", error]
                showAlert:YES];
        }];
}

- (IBAction)didChangeBadgeCount:(UISwitch *)sender
{
    [self badgeCountEnable:sender.on];
    [self badgeIncreaseEnable:NO];
}

- (IBAction)didChangeBadgeIncrease:(UISwitch *)sender
{
    [self badgeCountEnable:NO];
    [self badgeIncreaseEnable:sender.on];
}

- (void)badgeCountEnable:(BOOL)enabled
{
    self.enableBadgeCount.on = enabled;
    self.badgeCount.text = @"";
    self.badgeCount.enabled = enabled;
}

- (void)badgeIncreaseEnable:(BOOL)enabled
{
    self.enableBadgeIncrease.on = enabled;
    self.badgeIncrease.text = @"";
    self.badgeIncrease.enabled = enabled;
}

- (NSArray *)createActionButtons
{
    NSMutableArray *actionButtons = [NSMutableArray new];
    [self.actionButtons.subviews enumerateObjectsUsingBlock:^(__kindof UIView *row, NSUInteger idx, BOOL *stop) {
        UITextField *title = row.subviews[0];
        UITextField *actionId = row.subviews[1];

        [actionButtons addObject:[GetSocialNotificationButton createWithTitle:title.text actionId:actionId.text]];
    }];
    return actionButtons;
}

- (NSDictionary *)createActionData
{
    NSMutableDictionary *actionData = [NSMutableDictionary new];
    [self.actionData.subviews enumerateObjectsUsingBlock:^(__kindof UIView *row, NSUInteger idx, BOOL *stop) {
        UITextField *key = row.subviews[0];
        UITextField *val = row.subviews[1];
        actionData[key.text] = val.text;
    }];
    return actionData;
}

- (NSDictionary *)createTemplateData
{
    NSMutableDictionary *templateData = [NSMutableDictionary new];
    [self.templateData.subviews enumerateObjectsUsingBlock:^(__kindof UIView *row, NSUInteger idx, BOOL *stop) {
        UITextField *key = row.subviews[0];
        UITextField *val = row.subviews[1];
        templateData[key.text] = val.text;
    }];
    return templateData;
}

- (NSArray *)createUserIds
{
    NSMutableArray *customUserIds = [self.recipients mutableCopy];
    [self.customUserIds.subviews enumerateObjectsUsingBlock:^(__kindof UIView *row, NSUInteger idx, BOOL *stop) {
        UITextField *userId = row.subviews[0];
        [customUserIds addObject:userId.text];
    }];
    return customUserIds;
}

#pragma mark - UIPickerView

- (NSDictionary<NSString*, NSString*> *)actions
{
    return @{
        @"No Action" : DEFAULT_ACTION,
        @"Default" : @"custom",
        @"Open Activity" : GetSocialActionType.openActivity,
        @"Open Invites" : GetSocialActionType.openInvites,
        @"Open Profile" : GetSocialActionType.openProfile,
        @"Open URL" : GetSocialActionType.openUrl,
        @"Add Friend" : GetSocialActionType.addFriend,
        @"Custom Action" : @"my_custom_action"
    };
}

// clang-format off
- (NSDictionary *)pickersSetup
{
    return @{
        @(self.notificationAction.hash) : @{
            @"size" : @(self.actions.count),
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
    return [self.pickersSetup[@(pickerView.hash)][@"size"] integerValue];
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

- (IBAction)changeImage:(id)sender
{
    [self showImagePickerViewForMediaType:(NSString *)kUTTypeImage];
}

- (IBAction)changeVideo:(id)sender
{
    [self showImagePickerViewForMediaType:(NSString *)kUTTypeMovie];
}

- (IBAction)clearImage:(id)sender
{
    [self setVideoViewState:Visible];
    [self setImageViewState:Visible];
    self.customImageSectionHeight.constant -= IMAGE_HEIGHT;
}

- (IBAction)clearVideo:(id)sender
{
    [self setVideoViewState:Visible];
    [self setImageViewState:Visible];
    self.customVideoContent = nil;
    self.customVideoSectionHeight.constant -= IMAGE_HEIGHT;
}

- (void)showImagePickerViewForMediaType:(NSString *)mediaType
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.mediaTypes = @[ mediaType ];

    self.imagePicker.delegate = self;

    [self presentViewController:self.imagePicker animated:YES completion:nil];
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

- (void)useSelectedImageWithInfo:(NSDictionary<NSString *, id> *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    image = [image imageByResizeAndKeepRatio:CGSizeMake(MAX_WIDTH, MAX_HEIGHT)];

    self.customImagePreview.image = image;
    self.customImageSectionHeight.constant += IMAGE_HEIGHT;

    [self setImageViewState:Selected];
    [self setVideoViewState:Hidden];
}

- (void)useSelectedVideoWithInfo:(NSDictionary<NSString *, id> *)info
{
    NSURL *videoUrl = info[UIImagePickerControllerMediaURL];
    self.customVideoContent = [NSData dataWithContentsOfURL:videoUrl];
    UIImage *image = [self generateThumbnailImage:videoUrl];
    int maxWidth = (int)(self.view.bounds.size.width * 0.8);
    image = [image imageByResizeAndKeepRatio:CGSizeMake(maxWidth, (int)(maxWidth * 0.4))];

    self.customVideoPreview.image = image;
    self.customVideoSectionHeight.constant += IMAGE_HEIGHT;
    [self setVideoViewState:Selected];
    [self setImageViewState:Hidden];
}

- (void)setVideoViewState:(ViewState)state
{
    self.buttonChangeCustomVideo.hidden = state != Visible;
    self.buttonRemoveCustomVideo.hidden = state != Selected;
    self.customVideoPreview.hidden = state != Selected;
    if (state != Selected)
    {
        self.customVideoPreview.image = nil;
    }
}

- (void)setImageViewState:(ViewState)state
{
    self.buttonChangeCustomImage.hidden = state != Visible;
    self.buttonRemoveCustomImage.hidden = state != Selected;
    self.customImagePreview.hidden = state != Selected;
    if (state != Selected)
    {
        self.customImagePreview.image = nil;
    }
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        [self useSelectedImageWithInfo:info];
    }
    else
    {
        [self useSelectedVideoWithInfo:info];
    }

    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;
}

@end
