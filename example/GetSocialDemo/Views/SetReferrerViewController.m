//
//  SetReferrerViewController.m
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "SetReferrerViewController.h"
#import <GetSocial/GetSocial.h>

@interface SetReferrerViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *referrerIdTF;
@property (weak, nonatomic) IBOutlet UITextField *eventTF;
@property (weak, nonatomic) IBOutlet UITextField *key1TF;
@property (weak, nonatomic) IBOutlet UITextField *key2TF;
@property (weak, nonatomic) IBOutlet UITextField *key3TF;
@property (weak, nonatomic) IBOutlet UITextField *value1TF;
@property (weak, nonatomic) IBOutlet UITextField *value2TF;
@property (weak, nonatomic) IBOutlet UITextField *value3TF;

@property (nonatomic) NSArray<UITextField*>* customDataKeyFields;
@property (nonatomic) NSArray<UITextField*>* customDataValueFields;

@end

@implementation SetReferrerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.customDataKeyFields = @[self.key1TF, self.key2TF, self.key3TF];
    self.customDataValueFields = @[self.value1TF, self.value2TF, self.value3TF];
    

    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.scrollView.contentInset =
        UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, 0, self.scrollView.contentInset.right);
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, keyboardSize.height,
                                                    self.scrollView.contentInset.right);
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)invokeSetReferrer:(id)sender {

    NSString* referrerId = self.referrerIdTF.text;
    NSString* event = self.eventTF.text;
    NSMutableDictionary<NSString*, NSString*>* customData = [NSMutableDictionary new];
    [self.customDataKeyFields enumerateObjectsUsingBlock:^(UITextField* keyField, NSUInteger idx, BOOL * _Nonnull stop) {
        if (keyField.text != nil) {
            NSString* value = self.customDataValueFields[idx].text;
            if (value != nil) {
                customData[keyField.text] = value;
            }
        }
    }];
    [GetSocialInvites setReferrerWithId:[GetSocialUserId userWithId:referrerId] event:event customData:customData success:^() {
        [self log:LogLevelInfo context:NSStringFromSelector(_cmd) message:@"Referrer was set." showAlert:YES];
    } failure:^(NSError * _Nonnull error) {
        [self log:LogLevelError context:NSStringFromSelector(_cmd) message:[NSString stringWithFormat:@"Could not set referrer, error: %@", error.description] showAlert:YES];
    }];
}

@end
