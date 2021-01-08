//
//  MessageTableViewCell.h
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocialSDK/GetSocialSDK.h>


@interface MessageTableViewCell : UITableViewCell

@property(nonatomic, strong) GetSocialActivity *post;

@end

