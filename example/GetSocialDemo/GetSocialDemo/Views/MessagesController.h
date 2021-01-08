//
//  MessagesController.h
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import <GetSocialSDK/GetSocialSDK.h>
#import <UIKit/UIKit.h>

@interface MessagesController : UIViewController

@property(nonatomic) GetSocialUser *receiver;

- (void)updateMessages;

@end
