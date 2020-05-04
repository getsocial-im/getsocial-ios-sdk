/*
 *    	Copyright 2015-2019 GetSocial B.V.
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

#import <GetSocial/GetSocial.h>
#import <UIKit/UIKit.h>
#import "MainNavigationController.h"

@class ActionableMenuItem;
@class CheckableMenuItem;

@interface MainViewController : UIViewController<UIImagePickerControllerDelegate>

@property(nonatomic, strong) NSMutableArray *menu;
@property(nonatomic, strong) MainNavigationController *mainNavigationController;
@property(weak, nonatomic) IBOutlet UILabel *versionLabel;

- (void)loadMenu;
- (void)setUpGetSocial;

- (BOOL)handleNotification:(GetSocialNotification *)notification withContext:(NSDictionary *)context;

- (BOOL)handleAction:(GetSocialAction *)action;
- (void)handleAction:(NSString *)action withPost:(GetSocialActivityPost *)post;

+ (void)showPromoCodeFullInfo:(GetSocialPromoCode *)promoCode;

@end
