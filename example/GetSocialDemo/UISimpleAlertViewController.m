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

#import "UISimpleAlertViewController.h"
#import "UITextField+DisableCopyAndPaste.h"

@interface UISimpleAlertViewController ()

@property(copy, nonatomic) UISimpleAlertViewControllerDismissedHandler activeDismissHandler;

@property(strong, nonatomic) UIAlertController *activeAlertController;

@end

@implementation UISimpleAlertViewController

#pragma mark - Public (Initialization)

- (instancetype)initWithTitle:(NSString *)aTitle
                      message:(NSString *)aMessage
            cancelButtonTitle:(NSString *)aCancelTitle
            otherButtonTitles:(NSArray *)otherTitles
{
    self = [super init];
    if (self)
    {
        _activeAlertController = [UIAlertController alertControllerWithTitle:aTitle message:aMessage preferredStyle:UIAlertControllerStyleAlert];

        int selectedIndex = 0;
        for (NSString *buttonTitle in otherTitles)
        {
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:buttonTitle
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *_Nonnull selectedAction) {
                                                                    if (self.activeDismissHandler)
                                                                    {
                                                                        self.activeDismissHandler(selectedIndex, selectedAction.title, NO);
                                                                    }
                                                                }];

            [_activeAlertController addAction:alertAction];

            selectedIndex++;
        }
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:aCancelTitle
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *_Nonnull selectedAction) {
                                                                 if (self.activeDismissHandler)
                                                                 {
                                                                     self.activeDismissHandler(0, selectedAction.title, YES);
                                                                 }
                                                             }];
        [_activeAlertController addAction:cancelAction];
    }
    return self;
}

#pragma mark - Public (Functionality)

- (void)showWithDismissHandler:(UISimpleAlertViewControllerDismissedHandler)handler
{
    self.activeDismissHandler = handler;
    [[UISimpleAlertViewController rootViewController] presentViewController:self.activeAlertController animated:NO completion:nil];
}

- (void)addTextFieldWithPlaceholder:(NSString *)placeholder defaultText:(NSString *)defaultText isSecure:(BOOL)isSecure
{
    [self.activeAlertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
        textField.placeholder = placeholder;
        textField.text = defaultText;
        [textField setSecureTextEntry:isSecure];
    }];
}

- (NSString *)contentOfTextFieldAtIndex:(NSInteger)index
{
    return self.activeAlertController.textFields[index].text;
}

- (void)addNumericTextField
{
	[self.activeAlertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
		textField.placeholder = @"0";
		textField.keyboardType = UIKeyboardTypeNumberPad;
	}];
}

- (double)valueOfNumericTextFieldAtIndex:(NSInteger)index
{
	NSString* value = self.activeAlertController.textFields[index].text;
	return [value doubleValue];
}

+ (UIViewController *)rootViewController
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (rootViewController.presentedViewController != nil)
    {
        rootViewController = rootViewController.presentedViewController;
    }
    return rootViewController;
}

+ (void)hideAlertView
{
    [self.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
}

@end
