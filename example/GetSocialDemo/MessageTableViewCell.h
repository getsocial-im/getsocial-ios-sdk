//
//  MessageTableViewCell.h
//  GetSocialDemo
//
//  Copyright © 2019 GrambleWorld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocial/GetSocialActivityPost.h>


@interface MessageTableViewCell : UITableViewCell

@property(nonatomic, strong) GetSocialActivityPost *post;

@end

