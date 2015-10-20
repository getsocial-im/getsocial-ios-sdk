//
//  UIBAlertView.m
//  UIBAlertView
//
//  Created by Stav Ashuri on 1/31/13.
//  Copyright (c) 2013 Stav Ashuri. All rights reserved.
//

#import "UIBAlertView.h"

@interface UIBAlertView ()<UIAlertViewDelegate>

@property(strong, nonatomic) UIBAlertView *strongAlertReference;

@property(copy, nonatomic) UIBAlertDismissedHandler activeDismissHandler;

@property(strong, nonatomic) UIAlertView *activeAlert;

@end

@implementation UIBAlertView

#pragma mark - Public (Initialization)

- (id)initWithTitle:(NSString *)aTitle
            message:(NSString *)aMessage
  cancelButtonTitle:(NSString *)aCancelTitle
  otherButtonTitles:(NSArray *)otherTitles
{
    self = [super init];
    if (self)
    {
        UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:aTitle message:aMessage delegate:self cancelButtonTitle:aCancelTitle otherButtonTitles:nil];

        for (NSString *buttonTitle in otherTitles)
        {
            [alert addButtonWithTitle:buttonTitle];
        }

        self.activeAlert = alert;
    }
    return self;
}

#pragma mark - Public (Functionality)

- (void)showWithDismissHandler:(UIBAlertDismissedHandler)handler
{
    self.activeDismissHandler = handler;
    self.strongAlertReference = self;
    [self.activeAlert show];
}

#pragma mark UIAlertView passthroughs

- (UIAlertViewStyle)alertViewStyle
{
    return self.activeAlert.alertViewStyle;
}

- (void)setAlertViewStyle:(UIAlertViewStyle)alertViewStyle
{
    self.activeAlert.alertViewStyle = alertViewStyle;
}

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex
{
    return [self.activeAlert textFieldAtIndex:textFieldIndex];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.activeDismissHandler)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.activeDismissHandler(buttonIndex, [alertView buttonTitleAtIndex:buttonIndex], buttonIndex == alertView.cancelButtonIndex);
        });
    }
    self.strongAlertReference = nil;
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if (self.shouldEnableFirstOtherButtonHandler) return self.shouldEnableFirstOtherButtonHandler();

    return YES;
}

@end
