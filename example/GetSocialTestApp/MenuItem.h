/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MenuItemType)
{
    MenuItemTypeParent,
    MenuItemTypeActionable,
    MenuItemTypeCheckable,
    MenuItemTypeGroupedCheckable
};

@class ParentMenuItem;
@class ActionableMenuItem;
@class CheckableMenuItem;
@class GroupedCheckableMenuItem;

@interface MenuItem : NSObject

@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *detail;
@property(nonatomic, strong) ParentMenuItem *parentMenu;
@property(nonatomic, readonly) MenuItemType type;
@property(nonatomic, strong) NSString *name;

+ (ActionableMenuItem *)actionableMenuItemWithTitle:(NSString *)title action:(void (^)())action;
+ (ParentMenuItem *)parentMenuItemWithTitle:(NSString *)title;
+ (ParentMenuItem *)parentMenuItemWithTitle:(NSString *)title subitems:(NSMutableArray *)subitems;
+ (CheckableMenuItem *)checkableMenuItemWithTitle:(NSString *)title isChecked:(BOOL)isChecked action:(BOOL (^)(BOOL isChecked))action;
+ (GroupedCheckableMenuItem *)groupedCheckableMenuItemWithTitle:(NSString *)title isChecked:(BOOL)isChecked action:(BOOL (^)(BOOL isChecked))action;

@end

@interface ParentMenuItem : MenuItem

@property(nonatomic, strong) NSMutableArray *subitems;
@property(nonatomic, readonly) BOOL hasSubmenus;
@property(nonatomic, assign) BOOL isBeingUpdated;

- (void)addSubmenu:(MenuItem *)menuItem;
- (MenuItem *)menuItemWithName:(NSString *)name;

@end

@interface ActionableMenuItem : MenuItem

@property(nonatomic, copy) void (^action)();

@end

@interface CheckableMenuItem : MenuItem

@property(nonatomic, assign) BOOL isChecked;
@property(nonatomic, assign) NSInteger group;
@property(nonatomic, copy) BOOL (^action)(BOOL isChecked);

@end

@interface GroupedCheckableMenuItem : CheckableMenuItem

@end