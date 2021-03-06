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

#import "ActivityIndicatorViewController.h"
#import "MainNavigationController.h"
#import "UISimpleAlertViewController.h"
#import "UIViewController+GetSocial.h"

@implementation UIViewController (GetSocial)

static UIView *activityIndicatorView;

#pragma mark - Activity Indicator

- (ActivityIndicatorViewController *)activityViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    return [storyboard instantiateViewControllerWithIdentifier:@"activityIndicatorViewController"];
}

- (void)showActivityIndicatorView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ActivityIndicatorViewController *activityViewController = [self activityViewController];
        activityIndicatorView = activityViewController.view;
        activityIndicatorView.frame = self.view.bounds;
        [self.view addSubview:activityIndicatorView];
        self.view.userInteractionEnabled = NO;
    });
}

- (void)hideActivityIndicatorView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicatorView removeFromSuperview];
        activityIndicatorView = nil;
        self.view.userInteractionEnabled = YES;
    });
}

- (void)log:(LogLevel)level context:(NSString *)context message:(NSString *)message showAlert:(BOOL)showAlert
{
    [self log:level context:context message:message showAlert:showAlert showConsole:NO];
}

- (void)log:(LogLevel)level context:(NSString *)context message:(NSString *)message showAlert:(BOOL)showAlert showConsole:(BOOL)showConsole
{
    [[ConsoleViewController sharedController] log:level message:message context:context];

    if (showAlert)
    {
        switch (level)
        {
            case LogLevelInfo:
                [self showAlertWithTitle:[NSString stringWithFormat:@"Info (%@)", context] andText:message];
                break;

            case LogLevelWarning:
                [self showAlertWithTitle:[NSString stringWithFormat:@"Warning (%@)", context] andText:message];
                break;

            case LogLevelError:
                [self showAlertWithTitle:[NSString stringWithFormat:@"Error (%@)", context] andText:message];
                break;

            default:
                break;
        }
    }

    if (showConsole)
    {
        [self openConsole];
    }
}

- (void)showAlertWithText:(NSString *)text
{
    [self showAlertWithTitle:@"Info" andText:text];
}

- (void)showAlertWithTitle:(NSString *)title andText:(NSString *)text
{
    UISimpleAlertViewController *alertViewController =
        [[UISimpleAlertViewController alloc] initWithTitle:title message:text cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertViewController showWithDismissHandler:nil];
}

- (void)openConsole
{
    MainNavigationController *mainNavigationController = self.childViewControllers[0];
    if (mainNavigationController.topViewController != [ConsoleViewController sharedController])
    {
        [mainNavigationController pushViewController:[ConsoleViewController sharedController] animated:YES];
    }
}

@end
