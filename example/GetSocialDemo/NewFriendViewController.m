/*
 *    	Copyright 2015-2017 GetSocial B.V.
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

#import "NewFriendViewController.h"
#import "UIImageView+GetSocial.h"

@interface NewFriendViewController ()

@property (weak, nonatomic) IBOutlet UILabel *displayName;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@end

@implementation NewFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.displayName.text = self.publicUser.displayName;
    if(self.publicUser.avatarUrl.length > 0)
    {
        NSURL* avatarURL = [NSURL URLWithString:self.publicUser.avatarUrl];
        [self.avatar gs_setImageURL:avatarURL];
    }
    
}

- (IBAction)closeButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
