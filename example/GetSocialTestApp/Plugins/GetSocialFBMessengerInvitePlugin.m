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

#import <FBSDKShareKit/FBSDKShareKit.h>
#import "GetSocialFBMessengerInvitePlugin.h"

@interface GetSocialFBMessengerInvitePlugin ()<FBSDKSharingDelegate>

@property(nonatomic, copy) GetSocialInviteSuccessCallback successCallback;
@property(nonatomic, copy) GetSocialErrorCallback errorCallback;
@property(nonatomic, copy) GetSocialCancelCallback cancelCallback;

@end

@implementation GetSocialFBMessengerInvitePlugin

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.title = @"Facebook Messenger";
        self.imageUrl = @"https://scontent-ams3-1.xx.fbcdn.net/hphotos-xfa1/t39.2365-6/11057099_383365451847896_1818480781_n.png";
        self.details = @"GetSocial Smart Invite Plugin for Facebook Messenger";
    }
    return self;
}

- (void)inviteFriendsWithSubject:(NSString *)subject
                            text:(NSString *)text
                 referralDataUrl:(NSString *)referralDataUrl
                           image:(UIImage *)image
                onViewController:(UIViewController *)onViewController
                         success:(GetSocialInviteSuccessCallback)successCallback
                          cancel:(GetSocialCancelCallback)cancelCallback
                           error:(GetSocialErrorCallback)errorCallback
{
    self.successCallback = successCallback;
    self.errorCallback = errorCallback;
    self.cancelCallback = cancelCallback;

    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:referralDataUrl];
    content.contentTitle = subject;
    content.contentDescription = text;

    [FBSDKMessageDialog showWithContent:content delegate:self];
}

- (BOOL)isAvailableForDevice
{
    // check if FB Messenger is installed
    BOOL installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb-messenger-api://"]];
    return installed;
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    if (self.successCallback)
    {
        self.successCallback(nil);
    }
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    if (self.errorCallback)
    {
        self.errorCallback(error);
    }
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    if (self.cancelCallback)
    {
        self.cancelCallback();
    }
}

@end
