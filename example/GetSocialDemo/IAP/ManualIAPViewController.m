//
//  ManualIAPViewController.m
//  GetSocialInternalDemo
//
//
//  Copyright © 2019 GetSocial BV. All rights reserved.
//

#import "ManualIAPViewController.h"
#import <GetSocial/GetSocial.h>

@interface ManualIAPViewController ()

@property(weak, nonatomic) IBOutlet UITextField *productId;
@property(weak, nonatomic) IBOutlet UITextField *productTitle;
@property(weak, nonatomic) IBOutlet UITextField *productType;
@property(weak, nonatomic) IBOutlet UITextField *price;
@property(weak, nonatomic) IBOutlet UITextField *currencyCode;

@end

@implementation ManualIAPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.productType.text = @"item";
    self.price.text = @"1.10";
    self.currencyCode.text = @"EUR";
}

- (IBAction)trackPurchase:(id)sender
{
    GetSocialPurchaseData *purchaseData = [GetSocialPurchaseData new];
    purchaseData.productId = self.productId.text;
    purchaseData.productType = Item;
    purchaseData.productTitle = self.productTitle.text;
    purchaseData.price = [self.price.text floatValue];
    purchaseData.priceCurrency = self.currencyCode.text;
    purchaseData.purchaseDate = [NSDate date];
    purchaseData.transactionIdentifier = [[NSUUID UUID] UUIDString];

    if ([GetSocial trackPurchaseEvent:purchaseData])
    {
        [self log:LogLevelInfo context:NSStringFromSelector(_cmd) message:@"Purchase was tracked" showAlert:YES];
    }
    else
    {
        [self log:LogLevelError context:NSStringFromSelector(_cmd) message:@"Could not track purchase" showAlert:YES];
    }
}

@end
