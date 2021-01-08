/*
 *        Copyright 2015-2020 GetSocial B.V.
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

#import "GetSocialVKInvitePlugin.h"
#import "VKShareDialogController.h"

@implementation GetSocialVKInvitePlugin

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
    VKShareDialogController *shareDialog = [VKShareDialogController new];
    shareDialog.dismissAutomatically = YES;
    shareDialog.text = invite.text;

    if (invite.image)
    {
        VKUploadImage *uploadImage = [VKUploadImage uploadImageWithImage:invite.image andParams:[VKImageParameters pngImage]];
        shareDialog.uploadImages = @[ uploadImage ];
    }

    shareDialog.completionHandler = ^(VKShareDialogController *dialog, VKShareDialogControllerResult result) {
        if (result == VKShareDialogControllerResultDone)
        {
            successCallback(@{});
        }
        else
        {
            cancelCallback(@{});
        }
    };
    [viewController presentViewController:shareDialog animated:YES completion:nil];
}

@end
