//
//  MessagesController.h
//  GetSocialDemo
//
//  Copyright © 2019 GrambleWorld. All rights reserved.
//

#import <GetSocial/GetSocial.h>
#import <UIKit/UIKit.h>

@interface MessagesController : UIViewController

@property(nonatomic) GetSocialPublicUser *receiver;

- (void)updateMessages;

@end
