/**
 * Author: Demian Denker
 *
 * Published under the MIT License (MIT)
 * Copyright: (c) 2015 GetSocial B.V.
 */

#import "UserIdentityUtils.h"

@implementation UserIdentityUtils

+ (NSString *)installationIdWithSuffix:(NSString *)suffix
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [userDefaults objectForKey:@"installationId"];

    if (!uuid)
    {
        uuid = [[NSUUID UUID] UUIDString];
        [userDefaults setObject:uuid forKey:@"installationId"];
    }

    return [uuid stringByAppendingString:suffix];
}

+ (NSString *)displayNameForUserId:(NSString *)userId
{
    NSArray *displayNames = @[
        @"Batman",
        @"Spiderman",
        @"Captain America",
        @"Green Lantern",
        @"Wolverine",
        @"Catwomen",
        @"Iron Man",
        @"Superman",
        @"Wonder Woman",
        @"Aquaman"
    ];

    return [displayNames[[userId hash] % [displayNames count]] stringByAppendingString:@" iOS"];
}

+ (NSString *)avatarUrlForUserId:(NSString *)userId
{
    return [NSString stringWithFormat:@"http://api.adorable.io/avatars/200/%@.png", userId];
}

@end
