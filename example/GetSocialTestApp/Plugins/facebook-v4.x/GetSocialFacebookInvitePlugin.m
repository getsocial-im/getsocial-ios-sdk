/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "GetSocialFacebookInvitePlugin.h"
#import <GetSocial/GetSocial.h>

@interface GetSocialFacebookInvitePlugin ()

@property(nonatomic, copy) GetSocialInviteSuccessCallback sucessCallback;
@property(nonatomic, copy) GetSocialErrorCallback errorCallback;
@property(nonatomic, copy) GetSocialCancelCallback cancelCallback;

@end

@implementation GetSocialFacebookInvitePlugin

- (void)inviteFriendsWithSubject:(NSString *)subject
                            text:(NSString *)text
                 referralDataUrl:(NSString *)referralDataUrl
                           image:(UIImage *)image
                onViewController:(UIViewController*)onViewController
                         success:(GetSocialInviteSuccessCallback)successCallback
                          cancel:(GetSocialCancelCallback)cancelCallback
                           error:(GetSocialErrorCallback)errorCallback
{
    self.sucessCallback = successCallback;
    self.errorCallback = errorCallback;
    self.cancelCallback = cancelCallback;

    FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:referralDataUrl];

    [FBSDKAppInviteDialog showFromViewController:onViewController withContent:content delegate:self];
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
            if (self.sucessCallback)
            {
                self.sucessCallback(nil);
            }
        }
    }
    else
    {
        if (self.errorCallback)
        {
            self.errorCallback(nil);
        }
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
    if (self.errorCallback)
    {
        self.errorCallback(error);
    }
}

- (BOOL)isAvailableForDevice
{
    return self.enabled;
}

@end
