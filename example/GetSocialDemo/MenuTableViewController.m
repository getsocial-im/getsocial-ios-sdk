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

#import "MenuTableViewController.h"
#import <AudioToolbox/AudioServices.h>
#import <GetSocial/GetSocialUser.h>
#import "ConsoleViewController.h"
#import "MenuTableViewCell.h"
#import "PushNotificationView.h"
#import "UIStoryboard+GetSocial.h"
#import "UserIdentityViewController.h"
#import "UserViewController.h"

@interface MenuTableViewController ()

@property(nonatomic) BOOL isPressing;
@end

@implementation MenuTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.showUserIdentity)
    {
        UserIdentityViewController *userIdentityVC =
            [UIStoryboard viewControllerForName:@"UserIdentity" inStoryboard:GetSocialStoryboardUserManagement];

        userIdentityVC.view.frame =
            CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);

        self.navigationItem.titleView = userIdentityVC.view;

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openUserDetails:)];
        UILongPressGestureRecognizer *longPressGestureRecognizer =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(copyUserIdToClipboard:)];

        [self.navigationItem.titleView addGestureRecognizer:tapGestureRecognizer];
        [self.navigationItem.titleView addGestureRecognizer:longPressGestureRecognizer];
    }

    UIBarButtonItem *consoleItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(openConsole)];
    self.navigationItem.rightBarButtonItems = @[ consoleItem ];
}

- (void)openUserDetails:(UITapGestureRecognizer *)recognizer
{
    UserViewController *userVC = [UIStoryboard viewControllerForName:@"UserDetails" inStoryboard:GetSocialStoryboardUserManagement];
    [self.navigationController pushViewController:userVC animated:YES];
}

- (void)copyUserIdToClipboard:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.isPressing = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (!self.isPressing)
        {
            [UIPasteboard generalPasteboard].string = [GetSocialUser userId];
            [PushNotificationView showNotificationWithTitle:@"Clipboard"
                                                 andMessage:[NSString stringWithFormat:@"Copy %@ to clipboard.", [GetSocialUser userId]]];
            self.isPressing = YES;
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
}

- (void)openConsole
{
    [self.navigationController pushViewController:[ConsoleViewController sharedController] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menu.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menu"];

    MenuItem *currentMenuItem = self.menu[indexPath.row];

    cell.menuItem = currentMenuItem;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItem *currentMenuItem = self.menu[indexPath.row];

    switch (currentMenuItem.type)
    {
        case MenuItemTypeParent:
        {
            ParentMenuItem *parentMenuItem = (ParentMenuItem *)currentMenuItem;

            if (parentMenuItem.hasSubmenus)
            {
                MenuTableViewController *subMenu = [UIStoryboard viewControllerForName:@"Menu" inStoryboard:GetSocialStoryboardMain];
                subMenu.menu = parentMenuItem.subitems;
                subMenu.title = currentMenuItem.title;
                [self.navigationController pushViewController:subMenu animated:YES];
            }
        }
        break;

        case MenuItemTypeActionable:
        {
            ActionableMenuItem *actionableMenuItem = (ActionableMenuItem *)currentMenuItem;

            if (actionableMenuItem.action)
            {
                actionableMenuItem.action();
            }
        }
        break;

        case MenuItemTypeCheckable:
        case MenuItemTypeGroupedCheckable:
        {
            CheckableMenuItem *checkableMenuItem = (CheckableMenuItem *)currentMenuItem;

            if (checkableMenuItem.action && checkableMenuItem.action(!checkableMenuItem.isChecked))
            {
                checkableMenuItem.isChecked = !checkableMenuItem.isChecked;
            }
        }
        break;

        default:
            break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
