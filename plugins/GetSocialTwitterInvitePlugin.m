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

#import "GetSocialTwitterInvitePlugin.h"

@interface GetSocialTwitterInvitePlugin ()

@property(nonatomic) GetSocialInvite *invite;
@property(nonatomic) UIViewController *viewController;
@property(nonatomic, copy) void (^successCallback)(NSDictionary<NSString *,NSString *> *);
@property(nonatomic, copy) void (^cancelCallback)(NSDictionary<NSString *,NSString *> *);
@property(nonatomic, copy) void (^failureCallback)(NSError*, NSDictionary<NSString *,NSString *> *);

@end

@implementation GetSocialTwitterInvitePlugin

- (BOOL)isAvailableForDevice:(GetSocialInviteChannel *)inviteChannel
{
    return YES;
}

- (void)presentPluginWithInviteChannel:(GetSocialInviteChannel *)inviteChannel
                         invite:(GetSocialInvite *)invite
                      onViewController:(UIViewController *)viewController
                               success:(void (^)(NSDictionary<NSString *,NSString *> *))successCallback
                                cancel:(void (^)(NSDictionary<NSString *,NSString *> *))cancelCallback
                               failure:(void (^)(NSError* error, NSDictionary<NSString *,NSString *> *))failureCallback
{
    self.successCallback = successCallback;
    self.failureCallback = failureCallback;
    self.cancelCallback = cancelCallback;

    self.invite = invite;
    self.viewController = viewController;

    [self checkAvailableTwitterSession];
}

- (void)presentTweetComposer
{
    NSURL *videoUrl = nil;
    if (self.invite.videoUrl != nil)
    {
        videoUrl = [NSURL URLWithString:self.invite.videoUrl];
    }

    TWTRComposerViewController *composer = nil;
    if (videoUrl != nil)
    {
        composer = [[TWTRComposerViewController alloc] initWithInitialText:self.invite.text image:nil videoURL:videoUrl];
    }
    else
    {
        composer = [[TWTRComposerViewController alloc] initWithInitialText:self.invite.text image:self.invite.image videoURL:nil];
    }
    composer.delegate = self;
    [self.viewController presentViewController:composer animated:YES completion:nil];
}

- (void)checkAvailableTwitterSession
{
    if ([[Twitter sharedInstance].sessionStore hasLoggedInUsers])
    {
        [self presentTweetComposer];
    }
    else
    {
        [[Twitter sharedInstance] logInWithViewController:self.viewController
                                               completion:^(TWTRSession *_Nullable session, NSError *_Nullable error) {
                                                   if (session)
                                                   {
                                                       [self presentTweetComposer];
                                                   }
                                                   else
                                                   {
                                                       self.cancelCallback(@{});
                                                   }
                                               }];
    }
}

#pragma mark TWTRComposerViewControllerDelegate

/**
 * Called when the user taps the cancel button. This method will be called after the view controller is dismissed.
 */
- (void)composerDidCancel:(TWTRComposerViewController *)controller
{
    self.cancelCallback(@{});
}

/**
 * Called when the user successfully sends a Tweet. The resulting Tweet object is returned.
 * This method is called after the view controller is dimsissed and the API response is
 * received.
 */
- (void)composerDidSucceed:(TWTRComposerViewController *)controller withTweet:(TWTRTweet *)tweet
{
    self.successCallback(@{});
}

/**
 * This method is called if the composer is not able to send the Tweet.
 * The view controller will not be dismissed automatically if this method is called.
 */
- (void)composerDidFail:(TWTRComposerViewController *)controller withError:(NSError *)error
{
    self.failureCallback(error, @{});
}

@end
