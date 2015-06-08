//
//  ViewController.h
//  GetSocialTestApp
//
//  Created by Demian Denker on 28/01/15.
//  Copyright (c) 2015 GetSocial. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface ViewController : UIViewController <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;

@end

