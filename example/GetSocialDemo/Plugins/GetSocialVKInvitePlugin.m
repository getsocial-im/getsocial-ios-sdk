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

#import "GetSocialVKInvitePlugin.h"
#import "VKShareDialogController.h"

@implementation GetSocialVKInvitePlugin

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
    VKShareDialogController *shareDialog = [VKShareDialogController new];
    shareDialog.dismissAutomatically = YES;
    shareDialog.text = invitePackage.text;

    if (invitePackage.image)
    {
        VKUploadImage *uploadImage = [VKUploadImage uploadImageWithImage:invitePackage.image andParams:[VKImageParameters pngImage]];
        shareDialog.uploadImages = @[ uploadImage ];
    }

    shareDialog.completionHandler = ^(VKShareDialogController *dialog, VKShareDialogControllerResult result) {
        if (result == VKShareDialogControllerResultDone)
        {
            successCallback();
        }
        else
        {
            cancelCallback();
        }
    };
    [viewController presentViewController:shareDialog animated:YES completion:nil];
}

@end
