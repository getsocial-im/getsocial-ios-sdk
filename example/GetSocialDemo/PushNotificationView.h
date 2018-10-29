//
//
// Copyright (c) 2017 GrambleWorld. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushNotificationView : UIView

+ (void)showNotificationWithTitle:(NSString *)title andMessage:(NSString *)message;

- (void)showWithTitle:(NSString *)title andMessage:(NSString *)message;

@end