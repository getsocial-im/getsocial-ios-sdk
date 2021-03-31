//
//  SuggestedFriendsViewController.m
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "SuggestedFriendsViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
#import "SuggestedFriendTableViewCell.h"

@interface SuggestedFriendsViewController ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSMutableArray *selectedRows;
@property(weak, nonatomic) IBOutlet UITableView *suggestedFriends;

@end

@implementation SuggestedFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    self.suggestedFriends.delegate = self;
    self.suggestedFriends.dataSource = self;
    self.suggestedFriends.allowsMultipleSelection = YES;
}

- (NSMutableArray *)selectedRows
{
    if (!_selectedRows)
    {
        _selectedRows = [NSMutableArray new];
        for (int i = 0; i < self.friends.count; i++)
        {
            _selectedRows[i] = @(NO);
        }
    }
    return _selectedRows;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:^() {
                                 self.navigationController.toolbarHidden = YES;
                             }];
}

- (IBAction)didPressAdd:(id)sender
{
    NSMutableArray<GetSocialSuggestedFriend *> *friendsToAdd = [NSMutableArray new];
    for (int i = 0; i < self.selectedRows.count; i++)
    {
        if ([self.selectedRows[i] boolValue])
        {
            [friendsToAdd addObject:self.friends[i]];
        }
    }
    __block NSUInteger counter = friendsToAdd.count;
    if (counter == 0)
    {
        [self dismissViewControllerAnimated:YES
                                 completion:^() {
                                     self.navigationController.toolbarHidden = YES;
                                 }];
        return;
    }
    void (^onAddFriend)(void) = ^void() {
        if (--counter == 0)
        {
            [self dismissViewControllerAnimated:YES
                                     completion:^() {
                                         self.navigationController.toolbarHidden = YES;
                                     }];
        }
    };

    for (GetSocialSuggestedFriend *friend in friendsToAdd)
    {
        GetSocialUserIdList* userIds = [GetSocialUserIdList create:@[friend.userId]];
        [GetSocialCommunities addFriendsWithIds: userIds
            success:^(NSInteger result) {
                onAddFriend();
            }
            failure:^(NSError *_Nonnull error) {
                NSLog(@"Failed to add friend: %@", error.localizedDescription);
                onAddFriend();
            }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.friends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestedFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"suggestedFriendCell"];

    cell.user = self.friends[indexPath.row];
    BOOL isSelected = [self.selectedRows[indexPath.row] boolValue];
    cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRows[indexPath.row] = @(YES);
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRows[indexPath.row] = @(NO);
}

@end
