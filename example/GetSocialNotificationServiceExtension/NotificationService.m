//
//  NotificationService.m
//  GetSocialNotificationServiceExtension
//
//  Copyright © 2020 GetSocial. All rights reserved.
//

#import <GetSocialNotificationExtension/GetSocialNotificationExtension.h>
#import "NotificationService.h"

@interface NotificationService()

@property (nonatomic, strong) GetSocialNotificationRequestHandler *handler;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler
{
    self.handler = [GetSocialNotificationRequestHandler new];
    [self.handler handleNotificationRequest:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire
{
    [self.handler serviceExtensionTimeWillExpire];
}

@end
