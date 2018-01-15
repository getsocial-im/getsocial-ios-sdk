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

#import <FBSDKShareKit/FBSDKShareKit.h>
#import <GetSocial/GetSocialInviteChannelPlugin.h>

/*!
 * @abstract Facebook App Invite plugin.
 * @deprecated use FacebookSharePlugin instead.
 * Facebook is deprecating App Invites from February 5, 2018: https://developers.facebook.com/blog/post/2017/11/07/changes-developer-offerings/
 * More: https://blog.getsocial.im/facebook-deprecates-app-invites-are-you-ready/
 */
__deprecated_msg("Use FacebookSharePlugin instead, more: https://blog.getsocial.im/facebook-deprecates-app-invites-are-you-ready/")
@interface GetSocialFacebookInvitePlugin : GetSocialInviteChannelPlugin<FBSDKAppInviteDialogDelegate>

@end
