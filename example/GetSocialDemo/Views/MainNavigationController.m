/*
 *    	Copyright 2015-2020 GetSocial B.V.
 *
 *	Licensed under the Apache License, Version 2.0 (the "License");
 *	you may not use this file except in compliance with the License.
 *	You may obtain a copy of the License at
 *
 *    	http://www.apache.org/licenses/LICENSE-2.0
 *
 *	Unless required by applicable law or agreed to in writing, software
 *	distributed under the License is distributed on an "AS IS" BASIS,
 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *	See the License for the specific language governing permissions and
 *	limitations under the License.
 */

#import "MainNavigationController.h"
#import "MainViewController.h"
#import "MenuTableViewController.h"
#import "UIStoryboard+GetSocial.h"

@interface MainNavigationController ()

@property(nonatomic) BOOL skipAnimations;

@end

@implementation MainNavigationController

- (void)viewDidLoad
{
#ifdef SKIP_ANIMATIONS
    self.skipAnimations = YES;
#endif

    [super viewDidLoad];

    MenuTableViewController *menuViewController = [UIStoryboard viewControllerForName:@"Menu" inStoryboard:GetSocialStoryboardMain];
    menuViewController.menu = self.menu;
    menuViewController.showUserIdentity = YES;
    [self setViewControllers:@[ menuViewController ] animated:!self.skipAnimations];
}

@end