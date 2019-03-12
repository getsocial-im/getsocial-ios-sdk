//
//  UIStoryboard+GetSocial.h
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 9/5/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
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
    GetSocialStoryboardMessages
};

@interface UIStoryboard (GetSocial)

+ (instancetype)storyboardForType:(GetSocialStoryboard)type;

+ (id)viewControllerForName:(NSString *)name inStoryboard:(GetSocialStoryboard)storyboard;

@end
