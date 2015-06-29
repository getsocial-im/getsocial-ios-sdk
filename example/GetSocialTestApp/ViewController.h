//
//  ViewController.h
//  GetSocialTestApp
//
//  Created by Demian Denker on 28/01/15.
//  Copyright (c) 2015 GetSocial. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet FBSDKLoginButton *loginButton;

@end

