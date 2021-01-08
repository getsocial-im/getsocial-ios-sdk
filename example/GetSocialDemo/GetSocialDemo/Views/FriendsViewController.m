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

#import "FriendsViewController.h"
#import <GetSocialSDK/GetSocialSDK.h>
#import "FriendsTableViewCell.h"
#import "MessagesController.h"
#import "SuggestedFriendsViewController.h"
#import "UIStoryboard+GetSocial.h"
#import "UIViewController+GetSocial.h"

@interface FriendsViewController ()<UITableViewDelegate, UITableViewDataSource, FriendsTableViewCellDelegate>

@property(weak, nonatomic) IBOutlet UITextField *friendId;
@property(weak, nonatomic) IBOutlet UITableView *friendsList;

@property(nonatomic, strong) NSArray<GetSocialUser *> *friends;

@end

@implementation FriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadFriends];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addFriend:(id)sender
{
    [self.friendId endEditing:YES];
    [self showActivityIndicatorView];
    NSString *userId = self.friendId.text;
    __weak typeof(self) weakSelf = self;
    GetSocialUserIdList* userIdentifiers = [GetSocialUserIdList create:@[userId]];
    [GetSocialCommunities areFriendsWithIds: userIdentifiers success:^(NSDictionary<NSString *,NSNumber*> * result) {
        if (result.allValues.firstObject.boolValue)
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicatorView];
            [strongSelf showAlertWithText:@"User already is your friend"];
        }
        else
        {
            [GetSocialCommunities addFriendsWithIds:userIdentifiers
                success:^(NSInteger result) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf.friendId endEditing:YES];
                    strongSelf.friendId.text = @"";
                    [strongSelf hideActivityIndicatorView];
                    [strongSelf loadFriends];
                }
                failure:^(NSError *error) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf hideActivityIndicatorView];
                    [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
                }];
        }
    } failure:^(NSError * error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf hideActivityIndicatorView];
        [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
    }];
}

- (void)loadFriends
{
    [self showActivityIndicatorView];
    __weak typeof(self) weakSelf = self;
    GetSocialFriendsQuery* query = [GetSocialFriendsQuery ofUserWithId:[GetSocialUserId create: GetSocial.currentUser.userId]];
    GetSocialFriendsPagingQuery* pagingQuery = [[GetSocialFriendsPagingQuery alloc] initWithQuery:query];
    pagingQuery.limit = 1000;

    [GetSocialCommunities friendsWithQuery:pagingQuery
        success:^(GetSocialFriendsPagingResult* response) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.friends = response.friends;
            [strongSelf hideActivityIndicatorView];
            [strongSelf.friendsList reloadData];
        }
        failure:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicatorView];
            [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
        }];
}
- (IBAction)suggestFriends:(UIButton *)sender
{
    [self showActivityIndicatorView];
    __weak typeof(self) weakSelf = self;
    GetSocialFriendsQuery* query = [GetSocialFriendsQuery ofUserWithId:[GetSocialUserId create: GetSocial.currentUser.userId]];
    GetSocialFriendsPagingQuery* pagingQuery = [[GetSocialFriendsPagingQuery alloc] initWithQuery:query];
    pagingQuery.limit = 1000;
    [GetSocialCommunities suggestedFriendsWithQuery:pagingQuery
        success:^(GetSocialSuggestedFriendsPagingResult* response) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicatorView];
            [strongSelf showSuggestedFriends:response.suggestedFriends];
        }
        failure:^(NSError *_Nonnull error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicatorView];
            [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
        }];
}

- (void)showSuggestedFriends:(NSArray<GetSocialSuggestedFriend *> *)friends
{
    SuggestedFriendsViewController *suggestedFriendsVC =
        [UIStoryboard viewControllerForName:@"SuggestedFriends" inStoryboard:GetSocialStoryboardSocialGraph];
    suggestedFriendsVC.friends = friends;
    suggestedFriendsVC.modalInPopover = YES;
    [self.navigationController presentViewController:suggestedFriendsVC animated:YES completion:nil];
}

#pragma mark - FriendsTableViewCell

- (void)didClickRemoveFriend:(GetSocialUser *)user
{
    [self showActivityIndicatorView];
    __weak typeof(self) weakSelf = self;
    [GetSocialCommunities removeFriendsWithIds:[GetSocialUserIdList create:@[user.userId]]
        success:^(NSInteger result) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicatorView];
            [strongSelf loadFriends];
        }
        failure:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicatorView];
            [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
        }];
}

- (void)didClickMessageButton:(GetSocialUser *)user
{
    MessagesController *mc = [UIStoryboard viewControllerForName:@"Messages" inStoryboard:GetSocialStoryboardMessages];
    [mc setReceiver:user];

    [self.navigationController pushViewController:mc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.friends.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FriendsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];

    cell.user = self.friends[indexPath.row];
    cell.delegate = self;
    if ([cell.user.userId isEqualToString:self.markedFriendId])
    {
        cell.backgroundColor = [UIColor greenColor];
    }
    else
    {
        cell.backgroundColor = [UIColor clearColor];
    }

    return cell;
}

@end
