//
//  SuggestedFriendsViewController.h
//  GetSocialDemo
//
//  Created by Orest Savchak on 6/7/17.
//  Copyright © 2017 GrambleWorld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GetSocial/GetSocialSuggestedFriend.h>

@interface SuggestedFriendsViewController : UIViewController

@property (nonatomic, strong) NSArray<GetSocialSuggestedFriend *> *friends;

@end
