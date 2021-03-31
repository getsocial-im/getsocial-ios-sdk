//
//  NotificationsFilterViewController.m
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "NotificationsFilterViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
#import "UISimpleAlertViewController.h"

@interface NotificationsFilterViewController ()
@property(weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property(nonatomic, strong) NSDictionary<NSNumber *, NSString *> *types;

@property(nonatomic, strong) NSArray<NSString *> *statuses;
@property(nonatomic, strong) NSMutableArray<NSString *> *selectedStatuses;
@property(nonatomic, strong) NSArray<NSString *> *allTypes;

@property(nonatomic, strong) NSMutableArray<NSString *> *selectedTypes;
@property(nonatomic, strong) NSArray<NSString *> *notificationsTypes;
@property(nonatomic, strong) NSMutableArray<UITextField *> *addedActions;

@end

@implementation NotificationsFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray<NSString *> *types = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_types"];
    NSArray<NSString *> *statuses = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_statuses"];
    NSArray<NSString *> *actions = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_actions"];

    self.selectedStatuses = @[].mutableCopy;
    self.selectedTypes = @[].mutableCopy;
    self.addedActions = @[].mutableCopy;

    if (actions)
    {
        for (NSString *action in actions)
        {
            [self addAction].text = action;
        }
    }

    if (statuses)
    {
        [self.selectedStatuses addObjectsFromArray:statuses];
    }

    self.types = @{
        GetSocialNotificationType.comment : @"Comment",
        GetSocialNotificationType.likeActivity : @"Like Activity",
        GetSocialNotificationType.likeComment : @"Like Comment",
        GetSocialNotificationType.relatedComment : @"Related Comment",
        GetSocialNotificationType.newFriendship : @"New Friendship",
        GetSocialNotificationType.inviteAccepted : @"Invite Accepted",
        GetSocialNotificationType.mentionInComment : @"Mention In Comment",
        GetSocialNotificationType.mentionInActivity : @"Mention In Activity",
        GetSocialNotificationType.replyToComment : @"Reply To Comment",
        GetSocialNotificationType.targeting : @"Targeting",
        GetSocialNotificationType.direct : @"Direct",
        GetSocialNotificationType.sdk : @"SDK"
    };

    self.navigationController.toolbarHidden = NO;

    self.toolbar.items = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStylePlain target:self action:@selector(discard)],
        [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)]
    ];

    self.statuses = @[
        GetSocialNotificationStatus.read, GetSocialNotificationStatus.unread, GetSocialNotificationStatus.consumed, GetSocialNotificationStatus.ignored
    ];

    self.allTypes = @[ @"All", @"Custom" ];

    for (id type in types)
    {
        [self.selectedTypes addObject:self.types[type]];
    }
    self.notificationsTypes = self.selectedTypes.count ? [@[ @"All" ] arrayByAddingObjectsFromArray:self.types.allValues] : self.allTypes;

    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)discard
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save
{
    NSMutableDictionary *swapped = [NSMutableDictionary new];
    [self.types enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        swapped[value] = key;
    }];
    NSMutableArray *types = [@[] mutableCopy];
    for (NSString *type in self.selectedTypes)
    {
        [types addObject:swapped[type]];
    }

    NSMutableArray *actions = [NSMutableArray new];
    [self.addedActions enumerateObjectsUsingBlock:^(UITextField *obj, NSUInteger idx, BOOL *stop) {
        if (obj.text.length) [actions addObject:obj.text];
    }];

    [NSUserDefaults.standardUserDefaults setValue:self.selectedStatuses forKey:@"notification_statuses"];
    [NSUserDefaults.standardUserDefaults setValue:[NSArray arrayWithArray:types] forKey:@"notification_types"];
    [NSUserDefaults.standardUserDefaults setValue:[NSArray arrayWithArray:actions] forKey:@"notification_actions"];

    [self.delegate didUpdateFilter];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UITextField *)addAction
{
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, self.tableView.frame.size.width - 20, 40)];
    [self.addedActions addObject:textField];

    textField.accessibilityIdentifier = @"Action ID";
    textField.placeholder = @"Action ID";
    textField.enabled = YES;
    textField.userInteractionEnabled = YES;

    UIGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addActionButtonPlaceholderKey:)];
    [textField addGestureRecognizer:longTap];

    return textField;
}

- (void)removeAction:(UIButton *)sender
{
    [self.addedActions removeObjectAtIndex:sender.tag];
    [self.tableView reloadData];
}

- (void)addNewAction:(UIButton *)sender
{
    [[self addAction] becomeFirstResponder];
    [self.tableView reloadData];
}

- (NSArray *)sections
{
    return @[
        @{
            @"headerTitle": @"Notifications Status",
            @"numberOfRows": ^NSInteger() {
                return self.statuses.count;
}
, @"cellForRow" : ^UITableViewCell *(int row)
{
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.tableView.frame.size.width - 20, 40)];
    [tableViewCell.contentView addSubview:label];
    NSString *current = self.statuses[row];
    label.text = current;
    tableViewCell.accessoryType = [self.selectedStatuses containsObject:current] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return tableViewCell;
}
, @"didSelectRow" : ^(int row) {
    NSString *status = self.statuses[row];
    if ([self.selectedStatuses containsObject:status])
    {
        [self.selectedStatuses removeObject:status];
    }
    else
    {
        [self.selectedStatuses addObject:status];
    }
    [self.tableView reloadData];
}
}
, @{@"headerView" : ^UIView *(){
      UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
header.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.3];
UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 30)];
label.font = [UIFont boldSystemFontOfSize:17];
label.text = @"Notification Actions";

UIButton *addNew = [UIButton buttonWithType:UIButtonTypeSystem];
addNew.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
addNew.frame = CGRectMake(self.tableView.frame.size.width - 100, 0, 80, 30);
[addNew addTarget:self action:@selector(addNewAction:) forControlEvents:UIControlEventTouchUpInside];
[addNew setTitle:@"Add" forState:UIControlStateNormal];

[header addSubview:label];
[header addSubview:addNew];

return header;
}
,
            @"numberOfRows": ^NSInteger() {
                return self.addedActions.count;
            },
            @"cellForRow": ^UITableViewCell *(int row)
{
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];

    UIButton *remove = [UIButton buttonWithType:UIButtonTypeSystem];
    remove.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    remove.tag = row;
    remove.frame = CGRectMake(self.tableView.frame.size.width - 100, 20, 80, 20);
    [remove addTarget:self action:@selector(removeAction:) forControlEvents:UIControlEventTouchUpInside];
    [remove setTitle:@"Remove" forState:UIControlStateNormal];

    [tableViewCell.contentView addSubview:self.addedActions[row]];
    [tableViewCell.contentView addSubview:remove];

    return tableViewCell;
}
}
, @{@"headerTitle" : @"Notifications Type",
    @"numberOfRows" : ^NSInteger(){
        return self.notificationsTypes.count;
}
, @"cellForRow" : ^UITableViewCell *(int row)
{
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.tableView.frame.size.width - 20, 40)];
    [tableViewCell.contentView addSubview:label];
    if (self.notificationsTypes == self.allTypes)
    {
        tableViewCell.accessoryType = row == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else
    {
        tableViewCell.accessoryType =
            [self.selectedTypes containsObject:self.notificationsTypes[row]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    label.text = self.notificationsTypes[row];
    return tableViewCell;
}
, @"didSelectRow" : ^(int row) {
    if (row == 0)
    {
        self.notificationsTypes = self.allTypes;
        [self.selectedTypes removeAllObjects];
        [self.tableView reloadData];
    }
    else
    {
        if (row == 1 && self.notificationsTypes == self.allTypes)
        {
            self.notificationsTypes = [@[ @"All" ] arrayByAddingObjectsFromArray:self.types.allValues];
            [self.tableView reloadData];
        }
        else
        {
            NSString *type = self.notificationsTypes[row];
            if ([self.selectedTypes containsObject:type])
            {
                [self.selectedTypes removeObject:type];
            }
            else
            {
                [self.selectedTypes addObject:type];
            }
            [self.tableView reloadData];
        }
    }
}
},
    ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView * (^headerView)() = self.sections[section][@"headerView"];
    return headerView ? headerView() : nil;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section][@"headerTitle"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger (^rowsCount)() = self.sections[section][@"numberOfRows"];
    return rowsCount();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * (^cellForRow)(int) = self.sections[indexPath.section][@"cellForRow"];
    return cellForRow(indexPath.row);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    void (^didSelectRow)(int) = self.sections[indexPath.section][@"didSelectRow"];
    if (didSelectRow)
    {
        didSelectRow(indexPath.row);
    }
}

- (void)addActionButtonPlaceholderKey:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSArray *placeholders =
            @[ @"custom", GetSocialActionType.openActivity, GetSocialActionType.openProfile, GetSocialActionType.openInvites, GetSocialActionType.openUrl ];
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

@end
