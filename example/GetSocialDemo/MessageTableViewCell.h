//
//  MessageTableViewCell.h
//  GetSocialDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocial/GetSocialActivityPost.h>


@interface MessageTableViewCell : UITableViewCell

@property(nonatomic, strong) GetSocialActivityPost *post;

@end

