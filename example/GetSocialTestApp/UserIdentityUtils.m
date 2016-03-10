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

#import "UserIdentityUtils.h"

@implementation UserIdentityUtils

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

+ (NSString *)randomDisplayName
{
    return [self displayNameForUserId:[NSString stringWithFormat:@"%.0u", arc4random()]];
}

+ (NSString *)avatarUrlForUserId:(NSString *)userId
{
    return [NSString stringWithFormat:@"http://api.adorable.io/avatars/200/%@.png", userId];
}

+ (NSString *)randomAvatarUrl
{
    return [self avatarUrlForUserId:[NSString stringWithFormat:@"%.0f", [NSDate date].timeIntervalSince1970]];
}

@end
