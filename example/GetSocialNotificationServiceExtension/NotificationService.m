//
//  NotificationService.m
//  NotificationExtension
//
//  Created by Gábor Vass on 19/03/2021.
//

#import "NotificationService.h"
#if !TARGET_IPHONE_SIMULATOR
#import <GetSocialNotificationExtension/GetSocialNotificationExtension.h>
#endif
@interface NotificationService ()

#if !TARGET_IPHONE_SIMULATOR
@property (nonatomic, strong) GetSocialNotificationRequestHandler *handler;
#endif
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
#if !TARGET_IPHONE_SIMULATOR
	self.handler = [GetSocialNotificationRequestHandler new];
	[self.handler handleNotificationRequest:request withContentHandler:contentHandler];
#endif
}

- (void)serviceExtensionTimeWillExpire {
#if !TARGET_IPHONE_SIMULATOR
	[self.handler serviceExtensionTimeWillExpire];
#endif
}

@end
