/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import <GetSocial/GetSocialInvitePlugin.h>

@interface GetSocialFacebookInvitePlugin : GetSocialInvitePlugin

@property (nonatomic, copy) void (^authenticateUserHandler)();

@end
