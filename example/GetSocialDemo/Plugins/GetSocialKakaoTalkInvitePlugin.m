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

#import "GetSocialKakaoTalkInvitePlugin.h"
#import <KakaoLink/KakaoLink.h>
#import <KakaoMessageTemplate/KakaoMessageTemplate.h>
#import <KakaoOpenSDK/KakaoOpenSDK.h>

@implementation GetSocialKakaoTalkInvitePlugin

- (BOOL)isAvailableForDevice:(GetSocialInviteChannel *)inviteChannel
{
    BOOL isAvailable = [[KLKTalkLinkCenter sharedCenter] isAvailable];
    return isAvailable;
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

    KMTContentObject *contentObject = [KMTContentObject new];
    contentObject.title = invitePackage.text;

    KMTLinkObject *linkObject = [KMTLinkObject new];
    linkObject.mobileWebURL = [NSURL URLWithString:invitePackage.referralUrl];
    contentObject.link = linkObject;

    if (invitePackage.imageUrl && invitePackage.image)
    {
        CGFloat sharedImageWidth = 300;
        UIImage *image = invitePackage.image;
        CGFloat ratio = image.size.height / image.size.width;
        CGFloat height = ratio * sharedImageWidth;

        contentObject.imageURL = [NSURL URLWithString:invitePackage.imageUrl];
        contentObject.imageWidth = @(sharedImageWidth);
        contentObject.imageHeight = @(height);
    }
    KMTFeedTemplate *template = [KMTFeedTemplate feedTemplateWithContent:contentObject];
    [[KLKTalkLinkCenter sharedCenter] sendDefaultWithTemplate:template
        success:^(NSDictionary<NSString *, NSString *> *_Nullable warningMsg, NSDictionary<NSString *, NSString *> *_Nullable argumentMsg) {
            if (successCallback)
            {
                successCallback();
            }
        }
        failure:^(NSError *_Nonnull error) {
            if (failureCallback)
            {
                failureCallback(error);
            }
        }];
}

@end
