/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LogLevel)
{
    LogLevelInfo,
    LogLevelWarning,
    LogLevelError,
};

@interface ConsoleViewController : UIViewController

+ (instancetype)sharedController;

- (void)log:(LogLevel)level message:(NSString *)message context:(NSString*)context;

@end
