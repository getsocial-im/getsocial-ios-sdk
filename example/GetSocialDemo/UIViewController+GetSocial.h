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

#import <UIKit/UIKit.h>
#import "ConsoleViewController.h"

@interface UIViewController(GetSocial)

- (void)showActivityIndicator;
- (void)hideActivityIndicator;

- (void)log:(LogLevel)level context:(NSString *)context message:(NSString *)message showAlert:(BOOL)showAlert showConsole:(BOOL)showConsole;
- (void)log:(LogLevel)level context:(NSString *)context message:(NSString *)message showAlert:(BOOL)showAlert;

- (void)showAlertWithText:(NSString *)text;
- (void)showAlertWithTitle:(NSString *)title andText:(NSString *)text;

- (void)openConsole;

@end
