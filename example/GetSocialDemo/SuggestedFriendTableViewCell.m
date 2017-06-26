//
//  SuggestedFriendTableViewCell.m
//  GetSocialDemo
//
//  Created by Orest Savchak on 6/7/17.
//  Copyright © 2017 GrambleWorld. All rights reserved.
//

#import "SuggestedFriendTableViewCell.h"
#import "UIImageView+GetSocial.h"

@interface SuggestedFriendTableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *mutualFriendsCount;

@end

@implementation SuggestedFriendTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(GetSocialSuggestedFriend *)user
{
    _user = user;
    [self updateView];
}

- (void)updateView
{
    self.username.text = self.user.displayName;
    self.mutualFriendsCount.text = [NSString stringWithFormat:@"%d", self.user.mutualFriendsCount];
    if (self.user.avatarUrl.length > 0)
    {
        NSURL *url = [NSURL URLWithString:self.user.avatarUrl];
        [self.avatar gs_setImageURL:url];
    } else
    {
        [self.avatar setImage:[UIImage imageNamed:@"defaultAvatar.png"]];
    }
    
}


@end
