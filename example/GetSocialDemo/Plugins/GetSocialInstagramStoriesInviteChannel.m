#import "GetSocialInstagramStoriesInviteChannel.h"

@implementation GetSocialInstagramStoriesInviteChannel

- (BOOL)isAvailableForDevice:(__unused GetSocialInviteChannel *)inviteChannel
{
    NSURL *urlToCheck = [NSURL URLWithString:@"instagram-stories://share"];
    BOOL ableToResolveScheme = [[UIApplication sharedApplication] canOpenURL:urlToCheck];

    return ableToResolveScheme;
}

- (void)presentPluginWithInviteChannel:(__unused GetSocialInviteChannel *)inviteChannel
                         invite:(GetSocialInvite *)invite
                      onViewController:(__unused UIViewController *)viewController
                               success:(void (^)(NSDictionary<NSString *,NSString *> *))successCallback
                                cancel:(void (^)(NSDictionary<NSString *,NSString *> *))cancelCallback
                               failure:(void (^)(NSError* error, NSDictionary<NSString *,NSString *> *))failureCallback
{
    UIImage *image = invite.image;
    NSString *videoUrl = invite.videoUrl;
    NSString *inviteUrl = invite.referralUrl;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (videoUrl != nil)
        {
            NSData *videoData = [NSData dataWithContentsOfURL:[NSURL URLWithString:videoUrl]];
            if (videoData != nil)
            {
                [self openUrlSchemeForContentType:@"com.instagram.sharedSticker.backgroundVideo"
                                          content:videoData
                                        inviteUrl:inviteUrl
                                      stickerText:invite.text
                                          success:successCallback];
                return;
            }
        }
        
        if (image != nil)
        {
            NSData *imageData = UIImagePNGRepresentation(image);
            [self openUrlSchemeForContentType:@"com.instagram.sharedSticker.backgroundImage"
                                      content:imageData
                                    inviteUrl:inviteUrl
                                  stickerText:invite.text
                                      success:successCallback];

        }
        else
        {
            [self openUrlSchemeForContentType:@"com.instagram.sharedSticker.backgroundTopColor"
                                      content:@"#000000"
                                    inviteUrl:inviteUrl
                                  stickerText:invite.text
                                      success:successCallback];
        }
    });
}

- (void)openUrlSchemeForContentType:(NSString *)contentType
                            content:(NSObject *)content
                          inviteUrl:(NSString *)inviteUrl
                        stickerText:(NSString *)stickerText
                        success:(void (^)(NSDictionary<NSString *,NSString *> *))success
{
    NSURL *urlScheme = [NSURL URLWithString:@"instagram-stories://share"];
    NSData *sticker = [self createStickerFromText:stickerText];
    NSArray *pasteboardItems = @[ @{
        @"com.instagram.sharedSticker.contentURL" : inviteUrl,
        contentType : content,
        @"com.instagram.sharedSticker.stickerImage" : sticker
    } ];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10.0, *))
        {
            NSDictionary *pasteboardOptions = @{UIPasteboardOptionExpirationDate : [[NSDate date] dateByAddingTimeInterval:60 * 5]};
            [[UIPasteboard generalPasteboard] setItems:pasteboardItems options:pasteboardOptions];
            [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:nil];
        }
        else
        {
            [UIPasteboard generalPasteboard].items = pasteboardItems;
            [[UIApplication sharedApplication] openURL:urlScheme];
        }
        success(@{});
    });
}

- (NSData *)createStickerFromText:(NSString *)stickerText
{
    NSDictionary *attributes = @{
        NSFontAttributeName : [UIFont systemFontOfSize:15],
        NSForegroundColorAttributeName : [UIColor blackColor],
        NSBackgroundColorAttributeName : [UIColor lightGrayColor]
    };

    unsigned long charsInLine = 40;
    unsigned long textBoxWidth = stickerText.length > charsInLine ? 280 : 160;
    unsigned long textBoxHeight = stickerText.length;
    unsigned long textPaddingLeft = 15;
    unsigned long textPaddingTop = 15;

    unsigned long width = textBoxWidth + 25;
    unsigned long height = textBoxHeight + 25;

    // canvas-like rect for drawing
    CGRect pageRec = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContextWithOptions(pageRec.size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

    // rect with rounded corners
    CGPathRef roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width, height) cornerRadius:6].CGPath;
    CGContextAddPath(ctx, roundedRectPath);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);

    // inner rect for drawing text in it
    CGRect textRect = CGRectMake(textPaddingLeft, textPaddingTop, textBoxWidth, textBoxHeight);
    [stickerText drawInRect:textRect withAttributes:attributes];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    return UIImagePNGRepresentation(result);
}

@end
