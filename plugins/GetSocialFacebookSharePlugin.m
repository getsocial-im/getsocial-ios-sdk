/*
 *        Copyright 2015-2019 GetSocial B.V.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

#import "GetSocialFacebookSharePlugin.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <GetSocialUI/GetSocialUI.h>

@interface GetSocialFacebookSharePlugin ()<FBSDKSharingDelegate>

@end

@implementation GetSocialFacebookSharePlugin

- (BOOL)isAvailableForDevice:(GetSocialInviteChannel *)inviteChannel
{
    return YES;
}

- (void)presentPluginWithInviteChannel:(GetSocialInviteChannel *)inviteChannel
                         invitePackage:(GetSocialInvitePackage *)invitePackage
                      onViewController:(UIViewController *)viewController
                               success:(GetSocialInviteSuccessCallback)successCallback
                                cancel:(GetSocialInviteCancelCallback)cancelCallback
                               failure:(GetSocialFailureCallback)failureCallback
{
    self.successCallback = successCallback;
    self.failureCallback = failureCallback;
    self.cancelCallback = cancelCallback;

    [GetSocialUI closeView:YES];

    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:invitePackage.referralUrl];
    content.quote = invitePackage.text;

    FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] init];
    shareDialog.fromViewController = viewController;
    shareDialog.shareContent = content;
    shareDialog.delegate = self;
    shareDialog.mode = FBSDKShareDialogModeWeb;

    [shareDialog show];
}

- (void)sharer:(FBSDKShareDialog *)sharer didCompleteWithResults:(NSDictionary *)results
{
    [GetSocialUI restoreView];
    if (self.successCallback)
    {
        self.successCallback();
    }
}

- (void)sharer:(FBSDKShareDialog *)sharer didFailWithError:(NSError *)error
{
    [GetSocialUI restoreView];
    if (self.failureCallback)
    {
        self.failureCallback(error);
    }
}

- (void)sharerDidCancel:(FBSDKShareDialog *)sharer
{
    [GetSocialUI restoreView];
    if (self.cancelCallback)
    {
        self.cancelCallback();
    }
}

@end
