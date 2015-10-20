/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import <UIKit/UIKit.h>
#import "MainNavigationController.h"

@interface MainViewController : UIViewController<UINavigationControllerDelegate>

@property(nonatomic, strong) NSMutableArray *menu;
@property(nonatomic, strong) MainNavigationController *mainNavigationController;
@property(weak, nonatomic) IBOutlet UILabel *versionLabel;

@end
