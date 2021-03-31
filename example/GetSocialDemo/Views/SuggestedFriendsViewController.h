//
//  SuggestedFriendsViewController.h
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocialSDK/GetSocialSDK.h>

@interface SuggestedFriendsViewController : UIViewController

@property (nonatomic, strong) NSArray<GetSocialSuggestedFriend *> *friends;

@end
