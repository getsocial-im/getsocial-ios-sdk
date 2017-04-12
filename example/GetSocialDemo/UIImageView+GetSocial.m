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

#import "UIImageView+GetSocial.h"

@implementation UIImageView (GetSocial)

static NSCache *imageCache;

- (void)gs_setImageURL:(NSURL *)url
{
    if (imageCache == nil)
    {
        imageCache = [[NSCache alloc] init];
    }
    UIImage *imageFromCache = [imageCache objectForKey:url];
    if (imageFromCache)
    {
        [self setImage:imageFromCache];
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self downloadImageWithURL:url];
        });
    }
}

- (void)downloadImageWithURL:(NSURL *)url
{
    [[[NSURLSession sharedSession] dataTaskWithURL:url
                                 completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                     if (error == nil && httpResponse.statusCode == 200)
                                     {
                                         UIImage *downloadedImage = [UIImage imageWithData:data];
                                         if (downloadedImage)
                                         {
                                             [imageCache setObject:downloadedImage forKey:url];
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self setImage:downloadedImage];
                                             });
                                         }
                                     }
                                 }] resume];
}
@end
