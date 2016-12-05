/*
 *    	Copyright 2015-2016 GetSocial B.V.
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

- (void)inviteFriendsWithSubject:(NSString *)subject
                            text:(NSString *)text
                 referralDataUrl:(NSString *)referralDataUrl
                           image:(UIImage *)image
                onViewController:(UIViewController *)onViewController
                         success:(GetSocialInviteSuccessCallback)successCallback
                          cancel:(GetSocialCancelCallback)cancelCallback
                           error:(GetSocialErrorCallback)errorCallback
{
    KakaoTalkLinkObject *label
    = [KakaoTalkLinkObject createLabel:text];
    
    KakaoTalkLinkObject *webLink
    = [KakaoTalkLinkObject createWebLink:referralDataUrl
                                     url:referralDataUrl];
    
    [KOAppCall openKakaoTalkAppLink:@[label,webLink]];
    
    if(successCallback)
    {
        successCallback(nil);
    }
}

- (BOOL)isAvailableForDevice
{
    // check if Kakao Messenger is installed
    BOOL installed = [KOAppCall canOpenKakaoTalkAppLink];
    return self.enabled && installed;
}


@end
