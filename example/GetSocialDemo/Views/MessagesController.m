//
//  MessagesController.m
//  GetSocialDemo
//
//  Copyright © 2020 GetSocial BV. All rights reserved.
//

#import "MessagesController.h"
#import <GetSocial/GetSocial.h>
#import "MessageTableViewCell.h"
#import "UIViewController+GetSocial.h"

@interface MessagesController ()<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UITableView *chatView;
@property(weak, nonatomic) IBOutlet UITextField *input;
@property(weak, nonatomic) IBOutlet UIButton *sendButton;

@property(nonatomic, strong) NSArray<GetSocialActivity *> *posts;
@property(weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation MessagesController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.chatView.dataSource = self;
    self.input.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + keyboardSize.height);
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - keyboardSize.height);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadMessages];
}

- (void)updateMessages
{
    [self loadMessages];
}

- (void)loadMessages
{
    NSString *chatId = [self chatIdForUsers:@[ GetSocial.currentUser.userId, self.receiver.userId ]];
    GetSocialActivitiesQuery *query = [GetSocialActivitiesQuery inTopicWithId:chatId];
    GetSocialActivitiesPagingQuery* pagingQuery = [[GetSocialActivitiesPagingQuery alloc] initWithQuery:query];
    pagingQuery.limit = 100;
    __weak typeof(self) weakSelf = self;
    [GetSocialCommunities activitiesWithQuery:pagingQuery
        success:^(GetSocialActivitiesPagingResult* result) {
            NSLog(@"Successfully retrieved activities.");
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.posts = [[result.activities reverseObjectEnumerator] allObjects];
            [strongSelf.chatView reloadData];
            if (strongSelf.posts.count > 0)
            {
                [strongSelf.chatView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(strongSelf.posts.count - 1) inSection:0]
                                           atScrollPosition:UITableViewScrollPositionBottom
                                                   animated:YES];
            }
        }
        failure:^(NSError *error) {
            NSLog(@"Failed to get activities, error: %@", error);
        }];
}

- (NSString *)chatIdForUsers:(NSArray *)userIds
{
    NSArray *sortedIds = [userIds sortedArrayUsingSelector:@selector(compare:)];
    NSString *chatId = [sortedIds componentsJoinedByString:@"_"];

    return [@"chat_" stringByAppendingString:chatId];
}

- (IBAction)sendMessage:(id)sender
{
    if (self.input.text.length != 0)
    {
        GetSocialActivityContent *postContent = [GetSocialActivityContent new];
        postContent.text = self.input.text;
        __weak typeof(self) weakSelf = self;
        [self showActivityIndicatorView];
        GetSocialPostActivityTarget* target = [GetSocialPostActivityTarget topicWithId:[self chatIdForUsers:@[ GetSocial.currentUser.userId, self.receiver.userId ]]];
        [GetSocialCommunities postActivityContent:postContent
            target: target
            success:^(GetSocialActivity *post) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.input.text = @"";
                [strongSelf loadMessages];
                [strongSelf sendNotificationForMessage:postContent.text recipient:self.receiver.userId];
            }
            failure:^(NSError *error) {
                [self hideActivityIndicatorView];
                NSLog(@"Failed to post an activity, error: %@", error);
            }];
    }
}

- (void)sendNotificationForMessage:(NSString *)message recipient:(NSString *)recipientId
{
    // Sender user id to generate chat id on the recipient side
    NSDictionary *messageMetadata = @{@"open_messages_for_id" : GetSocial.currentUser.userId, @"open_messages_for_name" : GetSocial.currentUser.displayName};

    GetSocialAction *action = [GetSocialAction actionWithType:@"open_chat_message"];
    [action addData:messageMetadata];

    GetSocialNotificationContent *notificationContent = [GetSocialNotificationContent withText:message];
    notificationContent.title = GetSocial.currentUser.displayName;
    [notificationContent setAction: action];

    GetSocialSendNotificationTarget* target = [GetSocialSendNotificationTarget usersWithIds:[GetSocialUserIdList usersWithIds:@[ recipientId ]]];
    [GetSocialNotifications sendNotificationContent: notificationContent
                                             target: target
        success:^(void) {
            NSLog(@"Chat notification sent");
            [self hideActivityIndicatorView];
        }
        failure:^(NSError *error) {
            NSLog(@"Failed to send chat notifications, error: %@", error);
            [self hideActivityIndicatorView];
        }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.posts.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell"];

    [cell setPost:self.posts[indexPath.row]];

    return cell;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendMessage:textField];
    [textField resignFirstResponder];
    return YES;
}

@end
