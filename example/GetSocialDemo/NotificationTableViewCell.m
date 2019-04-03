//
//  NotificationTableViewCell.m
//  GetSocialInternalDemo
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import "NotificationTableViewCell.h"

@implementation NotificationTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)actionButton:(UIButton *)button
{
    [self.delegate actionButton:self.notification.actionButtons[button.tag].actionId notification:self.notification];
}

@end
