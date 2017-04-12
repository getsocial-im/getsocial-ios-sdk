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

#import "MenuItem.h"

@implementation MenuItem

- (instancetype)initWithType:(MenuItemType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
    }

    return self;
}

+ (ParentMenuItem *)parentMenuItemWithTitle:(NSString *)title
{
    ParentMenuItem *menuItem = [ParentMenuItem new];
    menuItem.title = title;
    menuItem.subitems = [NSMutableArray array];
    return menuItem;
}

+ (ParentMenuItem *)parentMenuItemWithTitle:(NSString *)title subitems:(NSMutableArray *)subitems
{
    ParentMenuItem *menuItem = [ParentMenuItem new];
    menuItem.title = title;
    return menuItem;
}

+ (ActionableMenuItem *)actionableMenuItemWithTitle:(NSString *)title action:(void (^)())action
{
    ActionableMenuItem *menuItem = [ActionableMenuItem new];
    menuItem.title = title;
    menuItem.action = action;
    return menuItem;
}

+ (CheckableMenuItem *)checkableMenuItemWithTitle:(NSString *)title isChecked:(BOOL)isChecked action:(BOOL (^)(BOOL isChecked))action
{
    CheckableMenuItem *menuItem = [CheckableMenuItem new];
    menuItem.title = title;
    menuItem.action = action;
    menuItem.isChecked = isChecked;
    return menuItem;
}

+ (GroupedCheckableMenuItem *)groupedCheckableMenuItemWithTitle:(NSString *)title isChecked:(BOOL)isChecked action:(BOOL (^)(BOOL isChecked))action
{
    GroupedCheckableMenuItem *menuItem = [GroupedCheckableMenuItem new];
    menuItem.title = title;
    menuItem.action = action;
    menuItem.isChecked = isChecked;
    return menuItem;
}

- (void)setTitle:(NSString *)title
{
    if (_title != title)
    {
        _title = title;
        [self postMenuDidChangeNotification];
    }
}

- (void)setDetail:(NSString *)detail
{
    if (_detail != detail)
    {
        _detail = detail;
        [self postMenuDidChangeNotification];
    }
}

- (void)postMenuDidChangeNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GetSocialMenuItemDidChange" object:self];
}

@end

@implementation ParentMenuItem

- (instancetype)init
{
    return self = [super initWithType:MenuItemTypeParent];
}

- (BOOL)hasSubmenus
{
    return (self.subitems && self.subitems.count > 0);
}

- (MenuItem *)menuItemWithName:(NSString *)name
{
    for (MenuItem *menuItem in self.subitems)
    {
        if ([menuItem.name isEqualToString:name])
        {
            return menuItem;
        }
    }

    return nil;
}

- (void)addSubmenu:(MenuItem *)menuItem
{
    [self.subitems addObject:menuItem];
    menuItem.parentMenu = self;
}

@end

@implementation ActionableMenuItem

- (instancetype)init
{
    return self = [super initWithType:MenuItemTypeActionable];
}

@end

@implementation CheckableMenuItem

- (instancetype)init
{
    return self = [super initWithType:MenuItemTypeCheckable];
}

- (void)setIsChecked:(BOOL)isChecked
{
    if (_isChecked != isChecked)
    {
        _isChecked = isChecked;
        [self postMenuDidChangeNotification];
    }
}

@end

@implementation GroupedCheckableMenuItem

- (instancetype)init
{
    return self = [super initWithType:MenuItemTypeGroupedCheckable];
}

- (void)setIsChecked:(BOOL)isChecked
{
    if (self.parentMenu && !self.parentMenu.isBeingUpdated)
    {
        self.parentMenu.isBeingUpdated = YES;
        for (MenuItem *menuItem in self.parentMenu.subitems)
        {
            if (menuItem.type == MenuItemTypeGroupedCheckable)
            {
                ((GroupedCheckableMenuItem *)menuItem).isChecked = NO;
            }
        }
        self.parentMenu.isBeingUpdated = NO;
    }

    [super setIsChecked:isChecked];
}

@end
