//
//  UIStoryboard+GetSocial.m
//  GetSocialInternalDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
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
        @(GetSocialStoryboardInAppPurchase) : @"InAppPurchase",
        @(GetSocialStoryboardMessages) : @"Messages",
        @(GetSocialStoryboardPromoCodes) : @"PromoCodes",
    }[@(type)];
}

+ (id)viewControllerForName:(NSString *)name inStoryboard:(GetSocialStoryboard)storyboard
{
    return [[UIStoryboard storyboardForType:storyboard] instantiateViewControllerWithIdentifier:name];
}

@end
