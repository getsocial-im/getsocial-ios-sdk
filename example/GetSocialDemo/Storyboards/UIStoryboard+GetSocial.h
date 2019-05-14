//
//  UIStoryboard+GetSocial.h
//  GetSocialInternalDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, GetSocialStoryboard) {
    GetSocialStoryboardMain,
    GetSocialStoryboardNotifications,
    GetSocialStoryboardUserManagement,
    GetSocialStoryboardSocialGraph,
    GetSocialStoryboardActivityFeed,
    GetSocialStoryboardSmartInvites,
    GetSocialStoryboardInAppPurchase,
    GetSocialStoryboardMessages,
    GetSocialStoryboardPromoCodes
};

@interface UIStoryboard (GetSocial)

+ (instancetype)storyboardForType:(GetSocialStoryboard)type;

+ (id)viewControllerForName:(NSString *)name inStoryboard:(GetSocialStoryboard)storyboard;

@end
