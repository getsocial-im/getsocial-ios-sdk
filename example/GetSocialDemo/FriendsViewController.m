/*
 *    	Copyright 2015-2017 GetSocial B.V.
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
#import "FriendsTableViewCell.h"
#import "UIViewController+GetSocial.h"
#import <GetSocial/GetSocial.h>

@interface FriendsViewController () <UITableViewDelegate, UITableViewDataSource, FriendsTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITextField *friendId;
@property (weak, nonatomic) IBOutlet UITableView *friendsList;

@property (nonatomic, strong) NSArray<GetSocialPublicUser *> *friends;

@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadFriends];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)addFriend:(id)sender
{
    [self.friendId endEditing:YES];
    [self showActivityIndicator];
    NSString *userId = self.friendId.text;
    __weak typeof(self) weakSelf = self;
    [GetSocialUser isFriend:userId success:^(BOOL isFriend) {
        if (isFriend)
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf hideActivityIndicator];
            [strongSelf showAlertWithText:@"User already is your friend"];
        } else
        {
            [GetSocialUser addFriend:userId success:^(int result){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf.friendId endEditing:YES];
                strongSelf.friendId.text = @"";
                [strongSelf hideActivityIndicator];
                [strongSelf loadFriends];
            } failure:^(NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf hideActivityIndicator];
                [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
            }];
        }
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf hideActivityIndicator];
        [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
    }];
}

- (void)loadFriends
{
    [self showActivityIndicator];
    __weak typeof(self) weakSelf = self;
    [GetSocialUser friendsWithOffset:0
                               limit:1000
                             success:^(NSArray<GetSocialPublicUser *> *friends) {
                                 __strong typeof(weakSelf) strongSelf = weakSelf;
                                 strongSelf.friends = [NSArray arrayWithArray:friends];
                                 [strongSelf hideActivityIndicator];
                                 [strongSelf.friendsList reloadData];
                             } failure:^(NSError *error) {
                                 __strong typeof(weakSelf) strongSelf = weakSelf;
                                 [strongSelf hideActivityIndicator];
                                 [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
                             }];
}

#pragma mark - FriendsTableViewCell

- (void)didClickRemoveFriend:(GetSocialPublicUser *)user
{
    [self showActivityIndicator];
    __weak typeof(self) weakSelf = self;
    [GetSocialUser removeFriend:user.userId
                        success:^(int result){
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf hideActivityIndicator];
                            [strongSelf loadFriends];
                        } failure:^(NSError *error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf hideActivityIndicator];
                            [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
                        }];
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
    if ([cell.user.userId isEqualToString:self.markedFriendId]) {
        cell.backgroundColor = [UIColor greenColor];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }

    return cell;
}

@end
