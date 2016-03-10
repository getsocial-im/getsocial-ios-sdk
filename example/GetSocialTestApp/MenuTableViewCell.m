/*
 *    	Copyright 2015-2016 GetSocial B.V.
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

#import "MenuTableViewCell.h"

@implementation MenuTableViewCell

- (void)setMenuItem:(MenuItem *)menuItem
{
    _menuItem = menuItem;

    [self updateCell];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"GetSocialMenuItemDidChange"
                                                      object:menuItem
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self updateCell];
                                                  }];
}

- (void)prepareForReuse
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateCell
{
    self.textLabel.text = self.menuItem.title;
    
    if (self.menuItem.detail)
    {
        self.detailTextLabel.text = self.menuItem.detail;
    }
    else
    {
        self.detailTextLabel.text = @"";
    }
    
    self.accessoryType = UITableViewCellAccessoryNone;

    switch (self.menuItem.type)
    {
        case MenuItemTypeParent:
        {
            ParentMenuItem *parentMenuItem = (ParentMenuItem *)self.menuItem;

            if (parentMenuItem.hasSubmenus)
            {
                self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        break;

        case MenuItemTypeActionable:
        {
            ActionableMenuItem *actionableMenuItem = (ActionableMenuItem *)self.menuItem;

            if (!actionableMenuItem.action)
            {
                self.userInteractionEnabled = NO;
                self.textLabel.enabled = NO;
            }
        }
        break;

        case MenuItemTypeCheckable:
        case MenuItemTypeGroupedCheckable:
        {
            CheckableMenuItem *checkableMenuItem = (CheckableMenuItem *)self.menuItem;

            if (checkableMenuItem.isChecked)
            {
                self.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
        break;

        default:
            break;
    }
}

@end
