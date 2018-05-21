//
//  NotificationsFilterViewController.m
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 5/8/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import "NotificationsFilterViewController.h"
#import <GetSocial/GetSocialConstants.h>

@interface NotificationsFilterViewController ()
@property(weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property(nonatomic, strong) NSDictionary<NSNumber *, NSString *> *types;

@property(nonatomic, strong) NSArray<NSString *> *statuses;
@property(nonatomic, strong) NSArray<NSString *> *allTypes;

@property(nonatomic, strong) NSMutableArray<NSString *> *selectedTypes;
@property(nonatomic, strong) NSString *notificationsStatus;
@property(nonatomic, strong) NSArray<NSString *> *notificationsTypes;

@end

@implementation NotificationsFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *types = [NSUserDefaults.standardUserDefaults arrayForKey:@"notification_types"];
    self.notificationsStatus = [NSUserDefaults.standardUserDefaults stringForKey:@"notification_status"];

    self.selectedTypes = [@[] mutableCopy];
    self.types = @{
        @(GetSocialNotificationTypeComment) : @"Comment",
        @(GetSocialNotificationTypeLikeActivity) : @"Like Activity",
        @(GetSocialNotificationTypeLikeComment) : @"Like Comment",
        @(GetSocialNotificationTypeRelatedComment) : @"Related Comment",
        @(GetSocialNotificationTypeNewFriendship) : @"New Friendship",
        @(GetSocialNotificationTypeInviteAccepted) : @"Invite Accepted",
        @(GetSocialNotificationTypeMentionInComment) : @"Mention In Comment",
        @(GetSocialNotificationTypeMentionInActivity) : @"Mention In Activity",
        @(GetSocialNotificationTypeReplyToComment) : @"Reply To Comment",
        @(GetSocialNotificationTypeTargeting) : @"Targeting",
        @(GetSocialNotificationTypeDirect) : @"Direct"
    };
    self.navigationController.toolbarHidden = NO;

    self.toolbar.items = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStylePlain target:self action:@selector(discard)],
        [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)]
    ];
    self.statuses = @[ @"Read and Unread", @"Read", @"Unread" ];

    self.allTypes = @[ @"All", @"Custom" ];

    self.notificationsStatus = self.notificationsStatus.length ? self.notificationsStatus : self.statuses[0];

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
    [NSUserDefaults.standardUserDefaults setValue:self.notificationsStatus forKey:@"notification_status"];
    NSMutableDictionary *swapped = [NSMutableDictionary new];
    [self.types enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        swapped[value] = key;
    }];
    NSMutableArray *types = [@[] mutableCopy];
    for (NSString *type in self.selectedTypes)
    {
        [types addObject:swapped[type]];
    }
    [NSUserDefaults.standardUserDefaults setValue:[NSArray arrayWithArray:types] forKey:@"notification_types"];

    [self.delegate didUpdateFilter];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Notifications Status";
    }
    else
    {
        return @"Notifications Type";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    else
    {
        return self.notificationsTypes.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 60)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, tableView.frame.size.width - 20, 40)];
    [tableViewCell.contentView addSubview:label];
    if (indexPath.section == 0)
    {
        label.text = self.notificationsStatus;
    }
    else
    {
        if (self.notificationsTypes == self.allTypes)
        {
            tableViewCell.accessoryType = indexPath.row == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else
        {
            tableViewCell.accessoryType = [self.selectedTypes containsObject:self.notificationsTypes[indexPath.row]]
                                              ? UITableViewCellAccessoryCheckmark
                                              : UITableViewCellAccessoryNone;
        }
        label.text = self.notificationsTypes[indexPath.row];
    }
    return tableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0)
    {
        [self selectStatus];
    }
    else
    {
        if (indexPath.row == 0)
        {
            self.notificationsTypes = self.allTypes;
            [self.selectedTypes removeAllObjects];
            [self.tableView reloadData];
        }
        else
        {
            if (indexPath.row == 1 && self.notificationsTypes == self.allTypes)
            {
                self.notificationsTypes = [@[ @"All" ] arrayByAddingObjectsFromArray:self.types.allValues];
                [self.tableView reloadData];
            }
            else
            {
                NSString *type = self.notificationsTypes[indexPath.row];
                BOOL contains = [self.selectedTypes containsObject:type];
                if (contains)
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
}

- (void)selectStatus
{
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"Choose notification statuses" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *status in self.statuses)
    {
        [alertController addAction:[UIAlertAction actionWithTitle:status
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              self.notificationsStatus = action.title;
                                                              [self.tableView reloadData];
                                                          }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
