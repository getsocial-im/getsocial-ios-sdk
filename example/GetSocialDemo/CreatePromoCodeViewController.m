//
//  CreatePromoCodeViewController.m
//  GetSocialDemo
//
//  Created by Orest Savchak on 5/8/19.
//  Copyright © 2019 GrambleWorld. All rights reserved.
//

#import "CreatePromoCodeViewController.h"
#import <GetSocial/GetSocial.h>
#import "MainViewController.h"
#import "UIViewController+GetSocial.h"

@interface CreatePromoCodeViewController ()
@property(weak, nonatomic) IBOutlet UITextField *promoCode;
@property(weak, nonatomic) IBOutlet UIView *customDataContainer;
@property(weak, nonatomic) IBOutlet UITextField *maxClaimCount;
@property(weak, nonatomic) IBOutlet UILabel *startTime;
@property(weak, nonatomic) IBOutlet UILabel *endTime;

@property(nonatomic, strong, nullable) NSDate *startDate;
@property(nonatomic, strong, nullable) NSDate *endDate;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *startDateContainerHeight;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *endDateContainerHeight;
@property(weak, nonatomic) IBOutlet UIDatePicker *startDatePicker;
@property(weak, nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property(weak, nonatomic) IBOutlet UIButton *changeStartTimeButton;
@property(weak, nonatomic) IBOutlet UIButton *changeEndTimeButton;

@property(nonatomic, strong) UIToolbar *keyboardToolbar;

@end

static NSInteger const DynamicRowHeight = 36;

@implementation CreatePromoCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.promoCode.inputAccessoryView = self.keyboardToolbar;
    self.maxClaimCount.inputAccessoryView = self.keyboardToolbar;
    [self.startDatePicker addTarget:self action:@selector(onStartDateChanged:) forControlEvents:UIControlEventValueChanged];
    [self.endDatePicker addTarget:self action:@selector(onEndDateChanged:) forControlEvents:UIControlEventValueChanged];
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

- (IBAction)addCustomData:(id)sender
{
    [self addDynamicRowType];
}

- (IBAction)changeStartTime:(id)sender
{
    if (self.startDateContainerHeight.constant == 0)
    {
        self.startTime.text = @"Start time: ";
        self.startDate = self.startDatePicker.date;
        self.startDateContainerHeight.constant = 216;
        [self.changeStartTimeButton setTitle:@"Hide" forState:UIControlStateNormal];
    }
    else
    {
        [self.changeStartTimeButton setTitle:@"Show" forState:UIControlStateNormal];
        self.startDateContainerHeight.constant = 0;
    }
}

- (void)onStartDateChanged:(id)sender
{
    self.startDate = self.startDatePicker.date;
}

- (IBAction)resetStartTime:(id)sender
{
    self.startDate = nil;
    self.startTime.text = @"Start time: (Start now)";
    self.startDateContainerHeight.constant = 0;
    [self.changeStartTimeButton setTitle:@"Change" forState:UIControlStateNormal];
}

- (IBAction)changeEndTime:(id)sender
{
    if (self.endDateContainerHeight.constant == 0)
    {
        self.endTime.text = @"End time: ";
        self.endDate = self.startDatePicker.date;
        self.endDateContainerHeight.constant = 216;
        [self.changeEndTimeButton setTitle:@"Hide" forState:UIControlStateNormal];
    }
    else
    {
        [self.changeEndTimeButton setTitle:@"Show" forState:UIControlStateNormal];
        self.endDateContainerHeight.constant = 0;
    }
}

- (void)onEndDateChanged:(id)sender
{
    self.endDate = self.endDatePicker.date;
}

- (IBAction)resetEndTime:(id)sender
{
    self.endDate = nil;
    self.endTime.text = @"End time: (Without limit)";
    self.endDateContainerHeight.constant = 0;
    [self.changeEndTimeButton setTitle:@"Change" forState:UIControlStateNormal];
}

- (IBAction)createPromoCode:(id)sender
{
    GetSocialPromoCodeBuilder *promoCodeBuilder =
        self.promoCode.text.length > 0 ? [GetSocialPromoCodeBuilder withCode:self.promoCode.text] : [GetSocialPromoCodeBuilder withRandomCode];

    [promoCodeBuilder addData:[self createCustomData]];
    [promoCodeBuilder setTimeLimitWithStartDate:self.startDate endDate:self.endDate];
    [promoCodeBuilder setMaxClaimCount:(uint)self.maxClaimCount.text.intValue];

    [GetSocial createPromoCode:promoCodeBuilder
        success:^(GetSocialPromoCode *_Nonnull promoCode) {
            [MainViewController showPromoCodeFullInfo:promoCode];
        }
        failure:^(NSError *_Nonnull error) {
            [self showAlertWithTitle:@"Failed to create promo code" andText:error.localizedDescription];
        }];
}

- (UIView *)addDynamicRowType
{
    UIView *container = self.customDataContainer;
    NSArray *inputs = @[ @"Key", @"Value" ];
    NSLayoutConstraint *heightConstraint = self.customDataContainer.constraints[0];
    NSInteger numberOfRow = container.subviews.count;

    UIView *row = [UIView new];
    row.tag = numberOfRow;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableString *constraint = [@"H:|" mutableCopy];
    NSMutableDictionary *views = [@{} mutableCopy];

    [inputs enumerateObjectsUsingBlock:^(NSString *input, NSUInteger idx, BOOL *stop) {
        UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 21)];

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
    UIView *container = self.customDataContainer;
    NSLayoutConstraint *heightConstraint = self.customDataContainer.constraints[0];

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

- (NSDictionary *)createCustomData
{
    NSMutableDictionary *customData = [NSMutableDictionary new];
    [self.customDataContainer.subviews enumerateObjectsUsingBlock:^(__kindof UIView *row, NSUInteger idx, BOOL *stop) {
        UITextField *key = row.subviews[0];
        UITextField *val = row.subviews[1];
        customData[key.text] = val.text;
    }];
    return customData;
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
