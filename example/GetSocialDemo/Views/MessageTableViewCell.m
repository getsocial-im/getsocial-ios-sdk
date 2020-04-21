//
//  MessageTableViewCell.m
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "MessageTableViewCell.h"
#import <GetSocial/GetSocial.h>

@interface MessageTableViewCell ()

@property(weak, nonatomic) IBOutlet UILabel *messageText;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSpace;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *trailingSpace;

@end

@implementation MessageTableViewCell

- (void)setPost:(GetSocialActivity *)post
{
    _post = post;
    [self updateView];
}

- (void)updateView
{
    self.messageText.text = [@" " stringByAppendingString:[_post.text stringByAppendingString:@" "]];
    self.messageText.layer.cornerRadius = 5;
    self.messageText.layer.masksToBounds = YES;
    self.messageText.textColor = UIColor.whiteColor;
    self.messageText.preferredMaxLayoutWidth = 300;
    if ([_post.author.userId isEqualToString:GetSocial.currentUser.userId])
    {
        self.messageText.backgroundColor = [self colorWithARGBString:@"#009688"];
        _trailingSpace.constant = 8;
        _trailingSpace.active = YES;
        _leadingSpace.active = NO;
    }
    else
    {
        self.messageText.backgroundColor = [self colorWithARGBString:@"#607D8B"];
        _leadingSpace.constant = 8;
        _leadingSpace.active = YES;
        _trailingSpace.active = NO;
    }

    [self.messageText sizeToFit];
    [self layoutIfNeeded];
}

- (UIColor *)colorWithARGBHex:(uint)hex
{
    int red, green, blue, alpha;

    blue = hex & 0x0000FF;
    green = ((hex & 0x00FF00) >> 8);
    red = ((hex & 0xFF0000) >> 16);
    alpha = ((hex & 0xFF000000) >> 24);

    return [UIColor colorWithRed:red / 255.0f green:green / 255.0f blue:blue / 255.0f alpha:alpha / 255.0f];
}

- (UIColor *)colorWithARGBString:(NSString *)hexString
{
    if (hexString.length != 0)
    {
        hexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];

        if ([hexString length] == 6)
        {
            hexString = [@"FF" stringByAppendingString:hexString];
        }

        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setCharactersToBeSkipped:[NSCharacterSet symbolCharacterSet]];
        uint baseColor = 0;

        if ([scanner scanHexInt:&baseColor])
        {
            return [self colorWithARGBHex:baseColor];
        }
    }
    return [UIColor clearColor];
}

@end
