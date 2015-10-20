/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "MainNavigationController.h"
#import "MenuTableViewController.h"

@interface MainNavigationController ()

@end

@implementation MainNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    MenuTableViewController *menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    menuViewController.menu = self.menu;
    menuViewController.showUserIdentity = YES;
    [self setViewControllers:@[ menuViewController ]];
}

@end
