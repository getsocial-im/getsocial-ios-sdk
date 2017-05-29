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

#import <KakaoOpenSDK/KakaoOpenSDK.h>
#import "GetSocialKakaoTalkInvitePlugin.h"

@implementation GetSocialKakaoTalkInvitePlugin

- (BOOL)isAvailableForDevice:(GetSocialInviteChannel *)inviteChannel
{
    return [KOAppCall canOpenKakaoTalkAppLink];
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
    
    NSMutableArray* sharedContent = [NSMutableArray array];
    KakaoTalkLinkObject *label = [KakaoTalkLinkObject createLabel:invitePackage.text];
    [sharedContent addObject:label];
    
    if(invitePackage.imageUrl && invitePackage.image)
    {
        CGFloat sharedImageWidth = 300;
        UIImage* image = invitePackage.image;
        CGFloat ratio = image.size.height / image.size.width;
        CGFloat height = ratio * sharedImageWidth;
        
        KakaoTalkLinkObject *imageLink = [KakaoTalkLinkObject createImage:invitePackage.imageUrl width:sharedImageWidth height:height];
        [sharedContent addObject:imageLink];
    }
    
    [KOAppCall openKakaoTalkAppLink:sharedContent];
    
    if(successCallback)
    {
        successCallback(nil);
    }
}

@end
