/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import <Foundation/Foundation.h>

@interface UserIdentityUtils : NSObject

+ (NSString *)installationIdWithSuffix:(NSString *)suffix;

+ (NSString *)displayNameForUserId:(NSString *)userId;

+ (NSString *)avatarUrlForUserId:(NSString *)userId;

@end
