/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import <UIKit/UIKit.h>

@interface CustomSmartInviteViewController : UIViewController<UIAlertViewDelegate>
@property(weak, nonatomic) IBOutlet UITextField *subjectField;
@property(weak, nonatomic) IBOutlet UITextField *textfield;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property(weak, nonatomic) IBOutlet UITextField *key1Field;
@property(weak, nonatomic) IBOutlet UITextField *key2Field;
@property(weak, nonatomic) IBOutlet UITextField *key3Field;
@property(weak, nonatomic) IBOutlet UITextField *value1Field;
@property(weak, nonatomic) IBOutlet UITextField *value2Field;
@property(weak, nonatomic) IBOutlet UITextField *value3Field;
@property(weak, nonatomic) IBOutlet UIButton *closeButton;
@end
