//
//  UIStoryboard+GetSocial.m
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 9/5/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import "UIStoryboard+GetSocial.h"

@implementation UIStoryboard (GetSocial)

+ (instancetype)storyboardForType:(GetSocialStoryboard)type
{
    return [UIStoryboard storyboardWithName:[self nameForType:type] bundle:[NSBundle mainBundle]];
}

+ (NSString *)nameForType:(GetSocialStoryboard)type
{
    return @{
        @(GetSocialStoryboardMain) : @"Main",
        @(GetSocialStoryboardNotifications) : @"Notifications",
        @(GetSocialStoryboardSocialGraph) : @"SocialGraph",
        @(GetSocialStoryboardUserManagement) : @"UserManagement",
        @(GetSocialStoryboardActivityFeed) : @"ActivityFeed",
        @(GetSocialStoryboardSmartInvites) : @"SmartInvites",
        @(GetSocialStoryboardInAppPurchase) : @"InAppPurchase"
    }[@(type)];
}

+ (id)viewControllerForName:(NSString *)name inStoryboard:(GetSocialStoryboard)storyboard
{
    return [[UIStoryboard storyboardForType:storyboard] instantiateViewControllerWithIdentifier:name];
}

@end
