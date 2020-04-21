//
// Copyright (c) 2020 GetSocial BV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN
@interface GetSocialNotificationExtensionHandler : NSObject

- (void)handleNotificationRequest:(UNNotificationRequest *)request
               withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler;

- (void)serviceExtensionTimeWillExpire;
@end
NS_ASSUME_NONNULL_END
