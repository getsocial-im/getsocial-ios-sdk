//
//  NotificationService.swift
//  ServiceExtension
//
//  Copyright © 2020 GetSocial. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var handler: GetSocialNotificationExtensionHandler?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.handler = GetSocialNotificationExtensionHandler.init()
        self.handler?.handle(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        self.handler?.serviceExtensionTimeWillExpire()
    }

}
