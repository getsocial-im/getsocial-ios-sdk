//
//  LimitedUITextField.m
//  GetSocialDemo
//

#import "UITextField+DisableCopyAndPaste.h"

@implementation UITextField (DisableCopyAndPaste)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}

@end
