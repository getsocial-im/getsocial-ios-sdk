/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
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
    return [super initWithType:MenuItemTypeParent];
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
    return [super initWithType:MenuItemTypeActionable];
}

@end

@implementation CheckableMenuItem

- (instancetype)init
{
    return [super initWithType:MenuItemTypeCheckable];
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
    return [super initWithType:MenuItemTypeGroupedCheckable];
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