//
//  NotificationsViewController.m
//  GetSocialInternalDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import "NotificationsViewController.h"
#import <GetSocial/GetSocial.h>
#import "MainViewController.h"
#import "NotificationTableViewCell.h"
#import "NotificationsFilterViewController.h"
#import "UIImageView+GetSocial.h"
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
    [self setNotifications:ids status:GetSocialNotificationStatusRead];
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
    NSArray<NSString *> *statuses = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_statuses"];
    NSArray<NSString *> *types = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_types"];
    NSArray<NSString *> *actions = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_actions"];

    GetSocialNotificationsQuery *query =
        statuses ? [GetSocialNotificationsQuery withStatuses:statuses] : [GetSocialNotificationsQuery withAllStatuses];

    if (types) [query setTypes:types];
    if (actions) [query setActions:actions];

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
    BOOL consumedOrIgnored = [@[ GetSocialNotificationStatusConsumed, GetSocialNotificationStatusIgnored ] containsObject:notification.status];
    BOOL wasRead = ![notification.status isEqualToString:GetSocialNotificationStatusUnread];
    cell.delegate = self;
    cell.notification = notification;
    cell.actionButtons.distribution = UIStackViewDistributionEqualSpacing;
    cell.isAccessibilityElement = YES;
    cell.accessibilityIdentifier = @"notification_item";
    cell.title.text = notification.title;
    if (consumedOrIgnored)
    {
        cell.title.text = [NSString stringWithFormat:@"%@ (%@)", cell.title.text, notification.status];
    }
    cell.text.text = notification.text;
    cell.date.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:notification.createdAt]];
    cell.readIndicator.hidden = wasRead;
    cell.backgroundColor = wasRead ? [UIColor whiteColor] : [UIColor lightGrayColor];

    if (notification.imageUrl != nil)
    {
        cell.mediaPreview.hidden = NO;
        cell.mediaHeight.constant = IMAGE_HEIGHT;
        [cell.mediaPreview gs_setImageURL:[NSURL URLWithString:notification.imageUrl]];
    }
    else
    {
        cell.mediaPreview.hidden = YES;
        cell.mediaHeight.constant = 0;
    }

    if (notification.videoUrl != nil)
    {
        cell.videoContentLabel.hidden = NO;
        cell.videoContentLabel.text = notification.videoUrl;
    }
    else
    {
        cell.videoContentLabel.hidden = YES;
    }

    if (notification.actionButtons.count == 0 || consumedOrIgnored)
    {
        cell.actionButtonsContainerHeight.constant = 0;
        cell.actionButtonsContainer.hidden = YES;
    }
    else
    {
        [cell.actionButtons.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
            [obj removeFromSuperview];
        }];
        for (GetSocialActionButton *actionButton in notification.actionButtons)
        {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.tag = [notification.actionButtons indexOfObject:actionButton];
            [button setTitle:actionButton.title forState:UIControlStateNormal];
            [button addTarget:cell action:@selector(actionButton:) forControlEvents:UIControlEventTouchUpInside];
            [button.heightAnchor constraintEqualToConstant:45].active = YES;
            [button.widthAnchor constraintEqualToConstant:100].active = YES;
            [cell.actionButtons addArrangedSubview:button];
        }
        cell.actionButtonsContainerHeight.constant = 45;
        cell.actionButtonsContainer.hidden = NO;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GetSocialNotification *selected = self.notifications[indexPath.row];
    [self.notificationsTableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([@[ GetSocialNotificationStatusConsumed, GetSocialNotificationStatusIgnored ] containsObject:selected.status])
    {
        return;
    }
    GetSocialNotificationStatus status =
        [selected.status isEqualToString:GetSocialNotificationStatusUnread] ? GetSocialNotificationStatusRead : GetSocialNotificationStatusUnread;

    [self setNotifications:@[ selected.notificationId ] status:status];
}

- (void)setNotifications:(NSArray<GetSocialId> *)notifications status:(GetSocialNotificationStatus)newStatus
{
    [GetSocialUser setNotificationsStatus:notifications
        status:newStatus
        success:^{
            for (uint i = 0; i < self.notifications.count; i++)
            {
                GetSocialNotification *selected = self.notifications[i];
                if ([notifications containsObject:selected.notificationId])
                {
                    GetSocialNotificationBuilder *builder = [GetSocialNotificationBuilder builderWithId:selected.notificationId];
                    [builder setAction:selected.notificationAction];
                    [builder setTitle:selected.title];
                    [builder setText:selected.text];
                    [builder setCreatedAt:selected.createdAt];
                    [builder setStatus:newStatus];
                    [builder setImageUrl:selected.imageUrl];
                    [builder setVideoUrl:selected.videoUrl];
                    [builder addActionButtons:selected.actionButtons];
                    [builder setNotificationType:selected.type];
                    self.notifications[i] = [builder build];
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

- (void)actionButton:(NSString *)action notification:(GetSocialNotification *)selected
{
    MainViewController *mainVC = (MainViewController *)self.parentViewController.parentViewController;
    [mainVC handleNotification:selected withContext:@{ @"wasClicked" : @(YES), @"actionId" : action }];

    GetSocialNotificationStatus newStatus =
        [action isEqualToString:GetSocialActionIdIgnore] ? GetSocialNotificationStatusIgnored : GetSocialNotificationStatusConsumed;

    GetSocialNotificationBuilder *builder = [GetSocialNotificationBuilder builderWithId:selected.notificationId];
    [builder setAction:selected.notificationAction];
    [builder setTitle:selected.title];
    [builder setText:selected.text];
    [builder setCreatedAt:selected.createdAt];
    [builder setStatus:newStatus];
    [builder setImageUrl:selected.imageUrl];
    [builder setVideoUrl:selected.videoUrl];
    [builder addActionButtons:selected.actionButtons];
    [builder setNotificationType:selected.type];
    self.notifications[[self.notifications indexOfObject:selected]] = [builder build];
    [self.notificationsTableView reloadData];
}

@end
