//
//  NotificationTableViewCell.h
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 5/7/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UIView *readIndicator;

@end
