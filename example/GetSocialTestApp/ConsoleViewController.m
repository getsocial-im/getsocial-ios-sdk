/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "ConsoleViewController.h"

@interface ConsoleViewController ()
@property(weak, nonatomic) IBOutlet UITextView *consoleTextView;
@property(strong, nonatomic) NSMutableAttributedString *consoleAttributedText;

@end

@implementation ConsoleViewController

+ (instancetype)sharedController
{
    static dispatch_once_t onceToken;
    static id sharedController;

    dispatch_once(&onceToken, ^{
        sharedController =
            [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"Console"];
    });

    return sharedController;
}

- (void)awakeFromNib
{
    self.consoleAttributedText = [[NSMutableAttributedString alloc] init];
}

- (void)log:(LogLevel)level message:(NSString *)message context:(NSString *)context
{
    if (context)
    {
        message = [NSString stringWithFormat:@"(%@) %@", context, message];
    }
    else
    {
        message = [NSString stringWithFormat:@"%@", message];
    }
    
    switch (level)
    {
        case LogLevelInfo:
            [self logMessage:message withColor:[UIColor greenColor]];
            break;

        case LogLevelWarning:
            [self logMessage:message withColor:[UIColor orangeColor]];
            break;

        case LogLevelError:
            [self logMessage:message withColor:[UIColor redColor]];
            break;

        default:
            break;
    }
}

- (void)logMessage:(NSString *)message withColor:(UIColor *)color
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
        [dateFormater setDateFormat:@"HH:mm:ss.SSS"];

        NSString *convertedDateString = [dateFormater stringFromDate:[NSDate date]];
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", convertedDateString, message];

        NSMutableAttributedString *attributedMessage =
            [[NSMutableAttributedString alloc] initWithString:logMessage
                                                   attributes:@{
                                                       NSFontAttributeName : [UIFont fontWithName:@"Courier" size:12],
                                                       NSForegroundColorAttributeName : color
                                                   }];

        [self.consoleAttributedText appendAttributedString:attributedMessage];

        [self updateTextView];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [self updateTextView];

    UIBarButtonItem *shareItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    self.navigationItem.rightBarButtonItems = @[ shareItem ];
}

- (void)updateTextView
{
    self.consoleTextView.attributedText = self.consoleAttributedText;
}

- (void)share
{
    NSString *string = [self.consoleTextView.attributedText string];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ string ] applicationActivities:nil];
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

@end
