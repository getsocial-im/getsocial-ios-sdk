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

#import <GetSocial/GetSocial.h>
#import <GetSocialUI/GetSocialUI.h>
#import <GetSocial/GetSocialActivityPostContent.h>
#import "PostActivityViewController.h"
#import "UISimpleAlertViewController.h"
#import "ConsoleViewController.h"
#import "UIViewController+GetSocial.h"
#import "UIImage+GetSocial.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

#define GLOBAL_FEED @"Global Feed"
#define CUSTOM_FEED @"Custom Feed"

#define MAX_WIDTH 1024.f
#define MAX_HEIGHT 768.f

#define GSLogInfo(bShowAlert, bShowConsole, sMessage, ...)                \
    [self log:LogLevelInfo                                                \
            context:NSStringFromSelector(_cmd)                            \
            message:[NSString stringWithFormat:(sMessage), ##__VA_ARGS__] \
          showAlert:bShowAlert ]

@interface PostActivityViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *contentText;
@property (weak, nonatomic) IBOutlet UITextField *buttonTitle;
@property (weak, nonatomic) IBOutlet UITextField *buttonAction;
@property (weak, nonatomic) IBOutlet UIImageView *contentImage;
@property (weak, nonatomic) IBOutlet UIPickerView *currentFeed;
@property (weak, nonatomic) IBOutlet UIButton *clearImageButton;

@property (nonatomic) NSData* contentVideo;

@property (nonatomic, strong) NSString *currentFeedTitle;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@end

@implementation PostActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentFeed.delegate = self;
    self.currentFeed.dataSource = self;
    self.currentFeedTitle = GLOBAL_FEED;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
    self.contentImage.hidden = YES;
    self.clearImageButton.hidden = YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)postActivity:(id)sender
{
    GetSocialActivityPostContent *content = [GetSocialActivityPostContent new];
    NSString *text = self.contentText.text;
    BOOL hasText = text.length > 0;

    NSString *buttonTitle = self.buttonTitle.text;
    NSString *buttonAction = self.buttonAction.text;
    BOOL hasButton = buttonTitle.length > 0 && buttonAction.length > 0;

    UIImage *image = self.contentImage.image;
    BOOL hasImage = image != nil;
    BOOL hasVideo = self.contentVideo != nil;

    BOOL globalFeed = [self.currentFeedTitle isEqualToString:GLOBAL_FEED];
    if (globalFeed && [GetSocialUser isAnonymous])
    {
        [self.delegate authorizeWithSuccess:^{
            [self postActivity:sender];
        }];
        return;
    }
    
    if (!hasText && !hasButton && !hasImage && !hasVideo)
    {
        [self showAlertWithTitle:@"Error" andText:@"Can not post activity without any data"];
        return;
    }
    if (hasText)
    {
        content.text = text;
    }
    if (hasImage)
    {
        content.image = image;
    }
    if (hasButton)
    {
        content.buttonTitle = buttonTitle;
        content.buttonAction = buttonAction;
    }
    
    if (hasVideo)
    {
        content.video = self.contentVideo;
    }

    [self showActivityIndicatorView];

    GetSocialUIActivityFeedView *view;

    if (globalFeed) {
        view = [GetSocialUI createGlobalActivityFeedView];
    } else {
        view = [GetSocialUI createActivityFeedView:@"DemoFeed"];
    }
    __weak typeof(self) weakSelf = self;

    [view setActionButtonHandler:^(NSString *action, GetSocialActivityPost *post) {
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf log:LogLevelInfo context:NSStringFromSelector(_cmd) message:[NSString stringWithFormat:@"Activity Feed button clicked, action: %@", action] showAlert:YES];
    }];
    
    GetSocialActivityResultCallback onSuccess = ^(id result) {
        typeof(weakSelf) strongSelf = self;
        [strongSelf hideActivityIndicatorView];
        [view show];
    };
    GetSocialFailureCallback onFailure = ^(NSError *error) {
        typeof(weakSelf) strongSelf = self;
        [strongSelf hideActivityIndicatorView];
        [strongSelf showAlertWithTitle:@"Error" andText:error.localizedDescription];
    };

    if (globalFeed) {
        [GetSocial postActivityToGlobalFeed:content success:onSuccess failure:onFailure];
    } else {
        [GetSocial postActivity:content toFeed:@"DemoFeed" success:onSuccess failure:onFailure];
    }
}
- (IBAction)changeVideo:(id)sender
{
    [self showImagePickerViewForMediaType:(NSString*)kUTTypeMovie];
}

- (IBAction)changeImage:(id)sender
{
    [self showImagePickerViewForMediaType:(NSString*)kUTTypeImage];
}

- (void)showImagePickerViewForMediaType:(NSString*)mediaType
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.mediaTypes = @[mediaType];

    self.imagePicker.delegate = self;
    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)clearImage:(id)sender
{
    self.contentImage.image = nil;
    self.contentImage.hidden = YES;
    self.clearImageButton.hidden = YES;
    self.contentVideo = nil;
}

- (NSArray *)feeds
{
    return @[GLOBAL_FEED, CUSTOM_FEED];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.feeds count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.feeds[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.currentFeedTitle = self.feeds[row];
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    NSString* mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString*)kUTTypeImage])
    {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        image = [image imageByResizeAndKeepRatio:CGSizeMake(MAX_WIDTH, MAX_HEIGHT)];
        
        self.contentImage.image = image;
    }
    else
    {
        NSURL* videoUrl = info[UIImagePickerControllerMediaURL];
        self.contentVideo = [NSData dataWithContentsOfURL:videoUrl];
        UIImage* image =  [self generateThumbnailImage:videoUrl];
        int max_width = self.view.bounds.size.width * 0.8;
        image = [image imageByResizeAndKeepRatio:CGSizeMake(max_width, max_width * 0.4)];

        self.contentImage.image = image;
    }
    
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;

    self.contentImage.hidden = NO;
    self.clearImageButton.hidden = NO;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imagePicker = nil;
}

- (UIImage *)generateThumbnailImage:(NSURL *)filepath
{
    AVAsset *asset = [AVAsset assetWithURL:filepath];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return thumbnail;
}


@end
