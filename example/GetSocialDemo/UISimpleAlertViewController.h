/*
 *    	Copyright 2015-2017 GetSocial B.V.
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

#import <Foundation/Foundation.h>

typedef void (^UISimpleAlertViewControllerDismissedHandler)(NSInteger selectedIndex, NSString *selectedTitle, BOOL didCancel);

@interface UISimpleAlertViewController : NSObject

- (id)initWithTitle:(NSString *)aTitle
            message:(NSString *)aMessage
  cancelButtonTitle:(NSString *)aCancelTitle
  otherButtonTitles:(NSArray *)otherTitles;

- (void)addTextFieldWithPlaceholder:(NSString*)placeholder defaultText:(NSString*)defaultText isSecure:(BOOL)isSecure;
- (NSString*)contentOfTextFieldAtIndex:(NSInteger)index;

- (void)showWithDismissHandler:(UISimpleAlertViewControllerDismissedHandler)handler onViewController:(UIViewController*)viewController;

@end
