//
//  NotificationsViewController.m
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "NotificationsViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
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
@property(nonatomic) NSString* nextCursor;

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
    [self setNotifications:ids status:GetSocialNotificationStatus.read];
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
    [GetSocialNotifications getWithQuery:self.baseQuery
        success:^(GetSocialNotificationsPagingResult* result) {
            self.nextCursor = result.nextCursor;
            self.isLoading = NO;
            [self hideActivityIndicatorView];
            self.notifications = [result.notifications mutableCopy];
            [self.notificationsTableView reloadData];
        }
        failure:^(NSError *error) {
            [self hideActivityIndicatorView];
            [self showAlertWithTitle:@"Failed to load notifications" andText:error.localizedDescription];
        }];
}

- (GetSocialNotificationsPagingQuery *)baseQuery
{
    NSArray<NSString *> *statuses = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_statuses"];
    NSArray<NSString *> *types = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_types"];
    NSArray<NSString *> *actions = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"notification_actions"];

    GetSocialNotificationsQuery *query =
        statuses ? [GetSocialNotificationsQuery withStatuses:statuses] : [GetSocialNotificationsQuery withAllStatuses];

    if (types) [query setTypes:types];
    if (actions) [query setActions:actions];

    GetSocialNotificationsPagingQuery* pagingQuery = [[GetSocialNotificationsPagingQuery alloc] initWithQuery:query];
    return pagingQuery;
}

- (void)loadMore
{
    if (self.isLoading || self.nextCursor.length == 0)
    {
        return;
    }
    self.isLoading = YES;
    GetSocialNotificationsPagingQuery *query = self.baseQuery;
    query.nextCursor = self.nextCursor;
    [GetSocialNotifications getWithQuery:query
        success:^(GetSocialNotificationsPagingResult* result) {
            self.nextCursor = result.nextCursor;
            if (result.notifications.count == 0)
            {
                return;
            }
            self.isLoading = NO;
            [self.notifications addObjectsFromArray:result.notifications];
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
    BOOL consumedOrIgnored = [@[ GetSocialNotificationStatus.consumed, GetSocialNotificationStatus.ignored ] containsObject:notification.status];
    BOOL wasRead = ![notification.status isEqualToString:GetSocialNotificationStatus.unread];
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
    cell.bgImageLabel.text = [NSString stringWithFormat:@"Bg image: %@", notification.customization.backgroundImageConfiguration];
    cell.titleColorLabel.text = [NSString stringWithFormat:@"Title color: %@", notification.customization.titleColor];
    cell.textColorLabel.text = [NSString stringWithFormat:@"Text color: %@", notification.customization.textColor];
    cell.backgroundColor = wasRead ? [UIColor whiteColor] : [UIColor lightGrayColor];

    if (notification.mediaAttachment.imageUrl != nil)
    {
        cell.mediaPreview.hidden = NO;
        cell.mediaHeight.constant = IMAGE_HEIGHT;
        [cell.mediaPreview gs_setImageURL:[NSURL URLWithString:notification.mediaAttachment.imageUrl]];
    }
    else
    {
        cell.mediaPreview.hidden = YES;
        cell.mediaHeight.constant = 0;
    }

    if (notification.mediaAttachment.videoUrl != nil)
    {
        cell.videoContentLabel.hidden = NO;
        cell.videoContentLabel.text = notification.mediaAttachment.videoUrl;
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
        for (GetSocialNotificationButton *actionButton in notification.actionButtons)
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
    if ([@[ GetSocialNotificationStatus.consumed, GetSocialNotificationStatus.ignored ] containsObject:selected.status])
    {
        return;
    }
    NSString* status =
        [selected.status isEqualToString:GetSocialNotificationStatus.unread] ? GetSocialNotificationStatus.read : GetSocialNotificationStatus.unread;

    [self setNotifications:@[ selected.notificationId ] status:status];
}

- (void)setNotifications:(NSArray<NSString*> *)notifications status:(NSString*)newStatus
{
    [GetSocialNotifications setStatusTo:newStatus
                      notificationIds: notifications
        success:^{
            for (uint i = 0; i < self.notifications.count; i++)
            {
                GetSocialNotification *selected = self.notifications[i];
                if ([notifications containsObject:selected.notificationId])
                {
                    GetSocialNotification* copiedNotification = [GetSocialPrivateNotificationBuilder updateNotification:selected newStatus:newStatus];
                    self.notifications[i] = copiedNotification;
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

    NSString* newStatus =
        [action isEqualToString:GetSocialNotificationButton.actionIdIgnore] ? GetSocialNotificationStatus.ignored : GetSocialNotificationStatus.consumed;

    GetSocialNotification* updatedNotification = [GetSocialPrivateNotificationBuilder updateNotification:selected newStatus:newStatus];
    self.notifications[[self.notifications indexOfObject:selected]] = updatedNotification;
    [self.notificationsTableView reloadData];
}

@end
