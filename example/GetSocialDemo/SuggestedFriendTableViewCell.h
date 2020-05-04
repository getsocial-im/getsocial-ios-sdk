//
//  SuggestedFriendTableViewCell.h
//  GetSocialDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocial/GetSocialSuggestedFriend.h>

@interface SuggestedFriendTableViewCell : UITableViewCell
@property (nonatomic, strong) GetSocialSuggestedFriend *user;
@end
