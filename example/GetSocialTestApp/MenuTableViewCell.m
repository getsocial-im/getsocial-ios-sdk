/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
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
