//
//  IAPViewController.m
//  GetSocialInternalDemo
//
//  Copyright © 2018 GrambleWorld. All rights reserved.
//

#import "IAPViewController.h"
#import <StoreKit/StoreKit.h>

@protocol IAPProductCellViewDelegate<NSObject>

- (void)buyProduct:(int)index;

@end

@interface IAPProductCellView : UITableViewCell

@property(weak, nonatomic) IBOutlet UILabel *title;
@property(weak, nonatomic) IBOutlet UIButton *buyButton;
@property(assign) id<IAPProductCellViewDelegate> delegate;

@end

@implementation IAPProductCellView

- (IBAction)buyProduct:(id)sender
{
    int index = [((UIButton *)sender).restorationIdentifier intValue];
    [self.delegate buyProduct:index];
}

@end

@interface IAPViewController ()<SKPaymentTransactionObserver, SKProductsRequestDelegate, UITableViewDataSource, UITableViewDelegate,
                                IAPProductCellViewDelegate>

@property(strong) NSArray *availableProducts;

@end

@implementation IAPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.availableProducts = [NSArray new];

    UIBarButtonItem *manualPurchaseButton = [[UIBarButtonItem alloc] initWithTitle:@"Manual Purchase"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(showManualPurchaseView)];
    self.navigationItem.rightBarButtonItem = manualPurchaseButton;

    [self setupIAP];
    [self loadProducts];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.availableProducts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = self.availableProducts[indexPath.row];
    IAPProductCellView *cellView = (IAPProductCellView *)[tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    cellView.title.text = product.localizedTitle;
    cellView.buyButton.restorationIdentifier = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    cellView.delegate = self;
    return cellView;
}

- (void)buyProduct:(int)index
{
    SKProduct *product = self.availableProducts[index];
    [self purchaseProduct:product];
}

- (void)purchaseProduct:(SKProduct *)product
{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)setupIAP
{
    if ([SKPaymentQueue canMakePayments])
    {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    else
    {
        NSLog(@"Cannot make payments");
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStateFailed:
                NSLog(@"Failed to buy, error: %@", transaction.error.localizedDescription);
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing...");
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"Done...");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)loadProducts
{
    NSSet *productIds = [NSSet setWithObjects:@"im.getsocial.sdk.demo.internal.iap.consumable", @"im.getsocial.sdk.demo.internal.iap.nonconsumable",
                                              @"im.getsocial.sdk.demo.internal.iap.subscription", nil];
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    productRequest.delegate = self;
    [productRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.availableProducts = [NSArray arrayWithArray:response.products];
    [self.tableView reloadData];
}

- (void)showManualPurchaseView
{
    [self performSegueWithIdentifier:@"manualPurchaseSegue" sender:self];
}

@end
