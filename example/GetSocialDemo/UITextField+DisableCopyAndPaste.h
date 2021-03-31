//
//  LimitedUITextField.h
//  GetSocialDemo
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextField (DisableCopyAndPaste)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;

@end

NS_ASSUME_NONNULL_END
