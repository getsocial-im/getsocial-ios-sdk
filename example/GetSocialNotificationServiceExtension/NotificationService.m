//
//  NotificationService.m
//  GetSocialNotificationServiceExtension
//
//  Copyright © 2020 GetSocial. All rights reserved.
//

#import <GetSocialExtension/GetSocialNotificationExtensionHandler.h>
#import "NotificationService.h"

@interface NotificationService()

@property (nonatomic, strong) GetSocialNotificationExtensionHandler *handler;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler
{
    self.handler = [GetSocialNotificationExtensionHandler new];
    [self.handler handleNotificationRequest:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire
{
    [self.handler serviceExtensionTimeWillExpire];
}

@end
