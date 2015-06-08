//
//  GetSocialFacebookInvitePlugin.m
//  testapp
//
//  Created by Demian Denker on 17/11/14.
//  Copyright (c) 2014 GetSocial. All rights reserved.
//

#import "GetSocialFacebookInvitePlugin.h"
#import "GetSocialFacebookUtils.h"
#import <GetSocial/GetSocial.h>
#import <FacebookSDK/FacebookSDK.h>

@implementation GetSocialFacebookInvitePlugin

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSRegularExpression* arrayKeyRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)\\[(\\d+)\\]" options:0 error:nil];
    
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        
        NSString* key = [kv[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSArray* matches = [arrayKeyRegex matchesInString:key options:0 range:NSMakeRange(0,[key length])];
        
        
        NSInteger index = -1;
        
        if( matches != nil && matches.count == 1 )
        {
            NSTextCheckingResult* result = matches[0];
            NSString* indexStr = [key substringWithRange:[result rangeAtIndex:2]];
            index = [indexStr integerValue];
            key = [key substringWithRange:[result rangeAtIndex:1]];
            key = [key stringByAppendingString:@"[]"];
        }
        
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if( index>=0 )
        {
            NSMutableDictionary* values = [params objectForKey:key];
            
            if( values == nil )
            {
                values = [NSMutableDictionary dictionary];
                [params setObject:values forKey:key];
            }
            
            [values setObject:val forKey:@(index)];
        }
        else
        {
            params[key] = val;
        }
    }
    return params;
}

-(void) inviteFriendsWithSubject:(NSString*) subject text:(NSString*) text referralDataUrl:(NSString*) referralDataUrl image:(UIImage*) image success:(GetSocialInviteSuccessCallback) successCallback cancel:(GetSocialCancelCallback) cancelCallback error:(GetSocialErrorCallback) errorCallback
{
    void (^inviteBlock)() = ^{
        [FBWebDialogs
         presentRequestsDialogModallyWithSession:nil
         message:@"Invite Friends"
         title:nil
         parameters:nil
         handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
             if (error) {
                 errorCallback(error);
             } else {
                 if (result == FBWebDialogResultDialogNotCompleted) {
                     cancelCallback();
                 } else {
                     // Handle the send request callback
                     NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                     if (![urlParams valueForKey:@"request"]) {
                         cancelCallback();
                         NSLog(@"User canceled request.");
                     } else {
                         // User clicked the Send button
                         NSString *requestID = [urlParams valueForKey:@"request"];
                         NSDictionary* to = [urlParams valueForKey:@"to[]"];
                         
                         NSLog(@"Request ID: %@", requestID);
                         successCallback(@{GetSocialInviteInfoKeyInviteId:requestID, GetSocialInviteInfoKeyInvitedUserIds:[to allValues]});
                     }
                 }
             }
         }];
    };
    
    if( ! [[FBSession activeSession] isOpen] )
    {
        [[GetSocialFacebookUtils sharedInstance] setOnSessionOpenHandler:inviteBlock];
        
        if (self.authenticateUserHandler)
        {
            self.authenticateUserHandler(inviteBlock);
        }
    }
    else
    {
        inviteBlock();
    }
}

- (BOOL) isAvailableForDevice
{
    return self.enabled;
}


@end
