//
//  SuggestedFriendsViewController.h
//  GetSocialDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocial/GetSocialSuggestedFriend.h>

@interface SuggestedFriendsViewController : UIViewController

@property (nonatomic, strong) NSArray<GetSocialSuggestedFriend *> *friends;

@end
