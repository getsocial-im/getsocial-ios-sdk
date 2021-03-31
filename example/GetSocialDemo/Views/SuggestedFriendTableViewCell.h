//
//  SuggestedFriendTableViewCell.h
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocialSDK/GetSocialSDK.h>

@interface SuggestedFriendTableViewCell : UITableViewCell
@property (nonatomic, strong) GetSocialSuggestedFriend *user;
@end
