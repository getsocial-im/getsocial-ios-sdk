/*
 *    	Copyright 2015-2020 GetSocial B.V.
 *
 *	Licensed under the Apache License, Version 2.0 (the "License");
 *	you may not use this file except in compliance with the License.
 *	You may obtain a copy of the License at
 *
 *    	http://www.apache.org/licenses/LICENSE-2.0
 *
 *	Unless required by applicable law or agreed to in writing, software
 *	distributed under the License is distributed on an "AS IS" BASIS,
 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *	See the License for the specific language governing permissions and
 *	limitations under the License.
 */

#import <UIKit/UIKit.h>

@interface CustomSmartInviteViewController : UIViewController<UIAlertViewDelegate>
@property(weak, nonatomic) IBOutlet UITextField *subjectField;
@property(weak, nonatomic) IBOutlet UITextField *textfield;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *imageUrlField;
@property (weak, nonatomic) IBOutlet UITextField *gifUrlField;
@property (weak, nonatomic) IBOutlet UITextField *videoUrlField;

@property(weak, nonatomic) IBOutlet UITextField *key1Field;
@property(weak, nonatomic) IBOutlet UITextField *key2Field;
@property(weak, nonatomic) IBOutlet UITextField *key3Field;
@property(weak, nonatomic) IBOutlet UITextField *value1Field;
@property(weak, nonatomic) IBOutlet UITextField *value2Field;
@property(weak, nonatomic) IBOutlet UITextField *value3Field;
@end
