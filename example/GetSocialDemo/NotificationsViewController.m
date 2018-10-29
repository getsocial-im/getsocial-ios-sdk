//
//  NotificationsViewController.m
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 5/7/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import "NotificationsViewController.h"
#import <GetSocial/GetSocial.h>
#import "NotificationTableViewCell.h"
#import "NotificationsFilterViewController.h"
#import "UIStoryboard+GetSocial.h"
#import "UIViewController+GetSocial.h"

static NSDateFormatter *dateFormatter;

@interface NotificationsViewController ()<UITableViewDataSource, UITableViewDelegate, NotificationsFilterViewControllerDelegate>

@property(weak, nonatomic) IBOutlet UITableView *notificationsTableView;

@property(nonatomic, strong) NSMutableArray<GetSocialNotification *> *notifications;
@property(nonatomic) BOOL isLoading;

@end

@implementation NotificationsViewController

+ (void)load
{
    dateFormatter = [NSDateFormatter new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *markAllAsRead =
        [[UIBarButtonItem alloc] initWithTitle:@"Read all" style:UIBarButtonItemStylePlain target:self action:@selector(readAll)];
    UIBarButtonItem *filter =
        [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(setupFilter)];
    self.navigationItem.rightBarButtonItems = @[ markAllAsRead, filter ];

    [dateFormatter setDateFormat:@"MM-dd-yyyy HH:mm"];
    self.notificationsTableView.delegate = self;
    self.notificationsTableView.dataSource = self;
    [self loadNotifications];
}

- (void)readAll
{
    NSMutableArray *ids = [@[] mutableCopy];
    for (GetSocialNotification *notification in self.notifications)
    {
        [ids addObject:notification.notificationId];
    }
    [self setNotifications:ids read:YES];
}

- (void)setupFilter
{
    NotificationsFilterViewController *notificationsFilterViewController =
        [UIStoryboard viewControllerForName:@"NotificationsFilter" inStoryboard:GetSocialStoryboardNotifications];

    notificationsFilterViewController.modalInPopover = YES;
    notificationsFilterViewController.delegate = self;
    [self.navigationController presentViewController:notificationsFilterViewController animated:YES completion:nil];
}

- (void)loadNotifications
{
    self.isLoading = YES;
    [self showActivityIndicatorView];
    [GetSocialUser notificationsWithQuery:self.baseQuery
        success:^(NSArray<GetSocialNotification *> *notifications) {
            self.isLoading = NO;
            [self hideActivityIndicatorView];
            self.notifications = [notifications mutableCopy];
            [self.notificationsTableView reloadData];
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            [self showAlertWithTitle:@"Failed to load notifications" andText:error.localizedDescription];
        }];
}

- (GetSocialNotificationsQuery *)baseQuery
{
    NSString *status = [NSUserDefaults.standardUserDefaults stringForKey:@"notification_status"];
    GetSocialNotificationsQuery *query;
    if ([status isEqualToString:@"Read"])
    {
        query = [GetSocialNotificationsQuery read];
    }
    else if ([status isEqualToString:@"Unread"])
    {
        query = [GetSocialNotificationsQuery unread];
    }
    else
    {
        query = [GetSocialNotificationsQuery readAndUnread];
    }
    [query setTypes:[NSUserDefaults.standardUserDefaults arrayForKey:@"notification_types"]];
    return query;
}

- (void)loadMore
{
    if (self.isLoading)
    {
        return;
    }
    self.isLoading = YES;
    GetSocialNotificationsQuery *query = self.baseQuery;
    [query setFilter:NotificationsBefore notificationId:self.notifications.lastObject.notificationId];
    [query setLimit:15];
    [GetSocialUser notificationsWithQuery:query
        success:^(NSArray<GetSocialNotification *> *notifications) {
            if (notifications.count == 0)
            {
                return;
            }
            self.isLoading = NO;
            [self.notifications addObjectsFromArray:notifications];
            [self.notificationsTableView reloadData];
        }
        failure:^(NSError *error) {
            self.isLoading = NO;
            [self showAlertWithTitle:@"Failed to load notifications" andText:error.localizedDescription];
        }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notificationsViewCell"];
    GetSocialNotification *notification = self.notifications[indexPath.row];
    cell.isAccessibilityElement = YES;
    cell.accessibilityIdentifier = @"notification_item";
    cell.title.text = notification.title;
    cell.text.text = notification.text;
    cell.date.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:notification.createdAt]];
    cell.readIndicator.hidden = notification.wasRead;
    cell.backgroundColor = notification.wasRead ? [UIColor whiteColor] : [UIColor lightGrayColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GetSocialNotification *selected = self.notifications[indexPath.row];
    [self.notificationsTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self setNotifications:@[ selected.notificationId ] read:!selected.wasRead];
}

- (void)setNotifications:(NSArray<GetSocialId> *)notifications read:(BOOL)read
{
    [GetSocialUser setNotificationsRead:notifications
        read:read
        success:^{
            for (uint i = 0; i < self.notifications.count; i++)
            {
                GetSocialNotification *selected = self.notifications[i];
                if ([notifications containsObject:selected.notificationId])
                {
                    self.notifications[i] = [[GetSocialNotification alloc] initWithId:selected.notificationId
                                                                                 type:selected.type
                                                                               action:selected.action
                                                                            createdAt:selected.createdAt
                                                                           actionData:selected.actionData
                                                                              wasRead:read
                                                                                title:selected.title
                                                                                 text:selected.text];
                }
            }
            [self.notificationsTableView reloadData];
        }
        failure:^(NSError *error) {
            [self showAlertWithTitle:@"Failed to read/unread notification" andText:error.localizedDescription];
        }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - scrollView.frame.size.height;
    if (actualPosition > 0 && self.notifications.count && actualPosition > contentHeight)
    {
        [self loadMore];
    }
}

- (void)didUpdateFilter
{
    [self loadNotifications];
}

@end
