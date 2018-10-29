//
//  SendNotificationViewController.m
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 9/6/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import "SendNotificationViewController.h"
#import <GetSocial/GetSocial.h>
#import <GetSocial/GetSocialConstants.h>
#import <GetSocial/GetSocialNotificationContent.h>
#import "UISimpleAlertViewController.h"
#import "UIViewController+GetSocial.h"

@interface SendNotificationViewController ()<UIPickerViewDelegate, UIPickerViewDataSource>
{
    BOOL keyboardIsShown;
}
@property(weak, nonatomic) IBOutlet UIView *templateContainer;
@property(weak, nonatomic) IBOutlet UIView *textContainer;

@property(weak, nonatomic) IBOutlet UITextField *templateName;
@property(weak, nonatomic) IBOutlet UIView *templateData;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *templateDataHeight;

@property(weak, nonatomic) IBOutlet UITextField *customText;
@property(weak, nonatomic) IBOutlet UITextField *customTitle;

@property(weak, nonatomic) IBOutlet UIPickerView *notificationAction;
@property(weak, nonatomic) IBOutlet UIView *actionData;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *actionDataHeight;

@property(weak, nonatomic) IBOutlet UIView *customUserIds;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *customUserIdsHeight;

@property(nonatomic, strong, readonly) NSDictionary *pickersSetup;

@property(nonatomic, strong, readonly) NSDictionary *actions;

@property(nonatomic, strong) NSMutableArray *recipients;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation SendNotificationViewController

typedef NS_ENUM(NSInteger, DynamicRowType) { TemplateData, NotificationData, UserIds };

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
    keyboardIsShown = NO;

    UIGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPlaceholder:)];
    [self.customText addGestureRecognizer:longTap];

    self.notificationAction.delegate = self;
    self.notificationAction.dataSource = self;

    self.recipients = [NSMutableArray new];

    self.templateData.translatesAutoresizingMaskIntoConstraints = NO;
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

- (void)addPlaceholder:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSArray *placeholders =
            @[ GetSocial_NotificationPlaceholder_CustomText_SenderDisplayName, GetSocial_NotificationPlaceholder_CustomText_ReceiverDisplayName ];

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

- (IBAction)addTemplateData:(id)sender
{
    [self addDynamicRowType:TemplateData];
}

- (IBAction)addActionData:(id)sender
{
    [self addDynamicRowType:NotificationData];
}

- (IBAction)toggleFriends:(UIButton *)sender
{
    [self toggleRecipient:GetSocial_NotificationPlaceholder_Receivers_Friends withButton:sender];
}

- (IBAction)toggleReferrer:(id)sender
{
    [self toggleRecipient:GetSocial_NotificationPlaceholder_Receivers_Referrer withButton:sender];
}

- (IBAction)toggleReferredUsers:(id)sender
{
    [self toggleRecipient:GetSocial_NotificationPlaceholder_Receivers_ReferredUsers withButton:sender];
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
        @(UserIds) : @{@"inputs" : @[ @"UserID" ], @"container" : self.customUserIds, @"constraint" : self.customUserIdsHeight}
    };
}

- (void)addDynamicRowType:(DynamicRowType)type
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
        [content addTemplatePlaceholders:[self createTemplateData]];
    }

    int selectedAction = [self.actions.allValues[[self.notificationAction selectedRowInComponent:0]] intValue];
    if (selectedAction != -1)
    {
        GetSocialNotificationActionType action = (GetSocialNotificationActionType)selectedAction;
        [content setActionType:action];
    }
    [content addActionData:[self createActionData]];

    [GetSocialUser sendNotification:[self createUserIds]
        withContent:content
        success:^(GetSocialNotificationsSummary *summary) {
            [self log:LogLevelInfo
                  context:@"Send Notification"
                  message:[NSString stringWithFormat:@"Successfully sent notifications to %d users.", summary.successfullySentCount]
                showAlert:YES];
        }
        failure:^(NSError *error) {
            [self log:LogLevelError
                  context:@"Send Notification"
                  message:[NSString stringWithFormat:@"Failed to send notification. Error: %@.", error]
                showAlert:YES];
        }];
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

- (NSDictionary *)actions
{
    return @{
        @"Default" : @(-1),
        @"Custom" : @(GetSocialNotificationActionCustom),
        @"Open Activity" : @(GetSocialNotificationActionOpenActivity),
        @"Open Invites" : @(GetSocialNotificationActionOpenInvites),
        @"Open Profile" : @(GetSocialNotificationActionOpenProfile),
        @"Open URL" : @(GetSocialNotificationActionOpenUrl),
    };
}

- (NSDictionary *)pickersSetup
{
    return @{ @(self.notificationAction.hash) : @{@"size" : @(self.actions.count), @"titles" : self.actions.allKeys} };
}

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
