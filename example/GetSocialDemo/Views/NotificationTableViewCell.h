//
//  NotificationTableViewCell.h
//  GetSocialInternalDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import <GetSocialSDK/GetSocialSDK.h>
#import <UIKit/UIKit.h>

#define IMAGE_HEIGHT 140

@protocol NotificationTableViewCellDelegate

- (void)actionButton:(NSString *)action notification:(GetSocialNotification *)notification;

@end

@interface NotificationTableViewCell : UITableViewCell

@property(nonatomic, weak) id<NotificationTableViewCellDelegate> delegate;
@property(nonatomic, strong) GetSocialNotification *notification;

@property(weak, nonatomic) IBOutlet UILabel *title;
@property(weak, nonatomic) IBOutlet UILabel *text;
@property(weak, nonatomic) IBOutlet UILabel *date;
@property(weak, nonatomic) IBOutlet UIView *readIndicator;
@property(weak, nonatomic) IBOutlet UIImageView *mediaPreview;
@property(weak, nonatomic) IBOutlet UITextView *videoContentLabel;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *mediaHeight;
@property(weak, nonatomic) IBOutlet UIView *actionButtonsContainer;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *actionButtonsContainerHeight;
@property(weak, nonatomic) IBOutlet UIStackView *actionButtons;

@property(weak, nonatomic) IBOutlet UILabel *bgImageLabel;
@property(weak, nonatomic) IBOutlet UILabel *titleColorLabel;
@property(weak, nonatomic) IBOutlet UILabel *textColorLabel;

@end
