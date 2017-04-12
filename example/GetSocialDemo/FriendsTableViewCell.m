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

#import <GetSocial/GetSocial.h>
#import "FriendsTableViewCell.h"
#import "UIImageView+GetSocial.h"

@interface FriendsTableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *userName;

@end

@implementation FriendsTableViewCell

- (void)setUser:(GetSocialPublicUser *)user
{
    _user = user;
    [self updateView];
}

- (void)updateView
{
    self.userName.text = self.user.displayName;
    if (self.user.avatarUrl.length > 0)
    {
        NSURL *url = [NSURL URLWithString:self.user.avatarUrl];
        [self.avatar gs_setImageURL:url];
    } else
    {
        [self.avatar setImage:[UIImage imageNamed:@"defaultAvatar.png"]];
    }

}

- (IBAction)didClickRemoveFriend:(id)sender
{
    [self.delegate didClickRemoveFriend:self.user];
}

@end
