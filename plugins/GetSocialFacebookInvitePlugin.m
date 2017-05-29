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

#import "GetSocialFacebookInvitePlugin.h"

@interface GetSocialFacebookInvitePlugin ()

@end

@implementation GetSocialFacebookInvitePlugin

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

    FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
    if(invitePackage.imageUrl && invitePackage.image)
    {
        NSURL* appImageUrl = [NSURL URLWithString:invitePackage.imageUrl];
        if (appImageUrl != nil)
        {
            content.appInvitePreviewImageURL = appImageUrl;
        }
    }
    content.appLinkURL = [NSURL URLWithString:invitePackage.referralUrl];
    [FBSDKAppInviteDialog showFromViewController:viewController withContent:content delegate:self];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
    BOOL didComplete = [results[@"didComplete"] boolValue];
    NSString *completionGesture = results[@"completionGesture"];

    if (didComplete)
    {
        if ([completionGesture isEqualToString:@"cancel"])
        {
            if (self.cancelCallback)
            {
                self.cancelCallback();
            }
        }
        else
        {
            if (self.successCallback)
            {
                self.successCallback();
            }
        }
    }
    else
    {
        if (results == nil)
        {
            if (self.cancelCallback)
            {
                self.cancelCallback();
            }
        }
        else if (self.failureCallback)
        {
            self.failureCallback([NSError errorWithDomain:@"GetSocialFacebookInvitePlugin" code:1000 userInfo:@{NSLocalizedDescriptionKey : @"Failed to invite."}]);
        }
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
    if (self.failureCallback)
    {
        self.failureCallback(error);
    }
}

@end
