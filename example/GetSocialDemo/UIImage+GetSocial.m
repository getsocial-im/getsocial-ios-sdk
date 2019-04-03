//
//
// Copyright (c) 2019 GetSocial BV. All rights reserved.
//

#import "UIImage+GetSocial.h"

@implementation UIImage (GetSocial)

- (UIImage *)imageByResizeAndKeepRatio:(CGSize)size
{
    return [UIImage resizeImage:self toSize:size];
}

/**
 * Resize an image to be not larger than MAX_WIDTH x MAX_HEIGHT and keep the ratio.
 * @param image
 * @return
 */
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size
{
    CGFloat scale = MAX(size.width / image.size.width, size.height / image.size.height);
    scale = MIN(1, scale);
    return [self imageWithImage:image scaledToSize:CGSizeMake(image.size.width * scale, image.size.height * scale)];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
