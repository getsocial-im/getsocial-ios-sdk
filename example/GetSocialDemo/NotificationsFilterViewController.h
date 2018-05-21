//
//  NotificationsFilterViewController.h
//  GetSocialInternalDemo
//
//  Created by Orest Savchak on 5/8/18.
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol NotificationsFilterViewControllerDelegate

- (void)didUpdateFilter;

@end

@interface NotificationsFilterViewController : UITableViewController

@property(nonatomic, weak) id<NotificationsFilterViewControllerDelegate> delegate;

@end
