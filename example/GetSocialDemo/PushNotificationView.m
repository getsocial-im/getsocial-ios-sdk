//
//
// Copyright (c) 2019 GetSocial BV. All rights reserved.
//

#import "PushNotificationView.h"

static NSInteger const HorizontalMargin = 8;
static NSInteger const VerticalMargin = 16;
static NSInteger const Height = 100;
static NSInteger const Padding = 10;

@implementation PushNotificationView

+ (void)showNotificationWithTitle:(NSString *)title andMessage:(NSString *)message
{
    CGFloat topPadding = 0;
    if (@available(iOS 11.0, *)) {
        topPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    }
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    PushNotificationView *notificationsView = [[PushNotificationView alloc]
        initWithFrame:CGRectMake(HorizontalMargin, topPadding - Height * 2, root.view.frame.size.width - HorizontalMargin * 2, Height)];

    [notificationsView showWithTitle:title andMessage:message];

    [root.view addSubview:notificationsView];
    [UIView animateWithDuration:0.2f
                     animations:^{
                         notificationsView.frame =
                             CGRectMake(HorizontalMargin, topPadding + VerticalMargin, root.view.frame.size.width - HorizontalMargin * 2, Height);
                     }];
}

- (void)showWithTitle:(NSString *)title andMessage:(NSString *)message
{
    self.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:0.98f];
    self.layer.cornerRadius = 15;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.8;
    self.layer.shadowRadius = 2.0;
    self.layer.shadowOffset = CGSizeMake(2.0, 2.0);

    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(Padding, 10, self.frame.size.width - Padding * 2, 30)];
    UILabel *messageView = [[UILabel alloc] initWithFrame:CGRectMake(Padding, 40, self.frame.size.width - Padding * 2, 60)];

    titleView.font = [UIFont boldSystemFontOfSize:15];
    messageView.font = [UIFont systemFontOfSize:15];
    messageView.numberOfLines = 0;

    titleView.text = title;
    messageView.text = message;

    [self addSubview:titleView];
    [self addSubview:messageView];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];

    [self addGestureRecognizer:pan];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self hideAnimated];
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    CGPoint center = pan.view.center;
    CGPoint translation = [pan translationInView:pan.view];
    if (pan.state == UIGestureRecognizerStateChanged)
    {
        if (center.y > 150)
        {
            translation.y = translation.y / 2.f;
        }
        center = CGPointMake(center.x, center.y + translation.y);
        pan.view.center = center;
        [pan setTranslation:CGPointZero inView:pan.view];
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        if (center.y < 20)
        {
            [self hideAnimated];
        }
        else
        {
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 pan.view.center = CGPointMake(center.x, 50 + VerticalMargin);
                             }];
        }
    }
}

- (void)hideAnimated
{
    [UIView animateWithDuration:0.3f
        animations:^{
            self.center = CGPointMake(self.center.x, -150);
        }
        completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
}
@end
