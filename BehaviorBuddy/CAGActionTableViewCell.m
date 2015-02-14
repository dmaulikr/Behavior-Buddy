#import "CAGActionTableViewCell.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@import Photos;
@import PhotosUI;

@interface CAGActionTableViewCell ()

@property (nonatomic) bool finished;
@property IBOutlet UILabel *actionNameLabel;
@property (nonatomic) UIImage *actionImage;
@property IBOutlet UIImageView *actionImageView;
@property CAGInitiation *behavior;
@property IBOutlet UIView *finishedView;
@property IBOutlet UILabel *finishedCheck;
@property IBOutlet UIView *colorView;
@property IBOutlet UIButton *playButton;
@property (nonatomic) bool playing;
@property (nonatomic) AVPlayerLayer *videoLayer;
@property (nonatomic) AVPlayer *videoPlayer;

@end

@implementation CAGActionTableViewCell

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
}

- (void)setCellInitiation:(CAGInitiation *)behavior
{
  if (self.behavior == behavior && !self.playing) {
    NSLog(@"already the same");
    return;
  }
  self.behavior = behavior;
  self.actionNameLabel.text = behavior.name;
  self.actionNameLabel.textColor = behavior.color;
  [self findActionImage];
}

- (void)showBehaviorImageTheOldWay:(NSURL *)imageUrl
{
  self.playButton.hidden = YES;
  ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myAsset)
  {
    if (myAsset) {
      UIImage *image = [self thumbnailForAsset:myAsset maxPixelSize:350*(1+self.behavior.imageSize)];
      self.actionImage = image;
      self.actionImageView.image = image;
      self.actionImageView.hidden = NO;
    } else {
      // don't have this image anymore
      self.behavior.imageUrl = nil;
      self.actionImage = nil;
      self.actionImageView.image = nil;
    }
  };
  
  ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
  {
    NSLog(@"Image access error: %@", [myerror localizedDescription]);
  };
  
  ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
  [assetslibrary assetForURL:imageUrl
                 resultBlock:resultblock
                failureBlock:failureblock];
}

// Helper methods for thumbnailForAsset:maxPixelSize:
static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
  ALAssetRepresentation *rep = (__bridge id)info;
  
  NSError *error = nil;
  size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
  
  if (countRead == 0 && error) {
    // We have no way of passing this info back to the caller, so we log it, at least.
    NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
  }
  
  return countRead;
}

static void releaseAssetCallback(void *info) {
  // The info here is an ALAssetRepresentation which we CFRetain in thumbnailForAsset:maxPixelSize:.
  // This release balances that retain.
  CFRelease(info);
}

// Returns a UIImage for the given asset, with size length at most the passed size.
// The resulting UIImage will be already rotated to UIImageOrientationUp, so its CGImageRef
// can be used directly without additional rotation handling.
// This is done synchronously, so you should call this method on a background queue/thread.
- (UIImage *)thumbnailForAsset:(ALAsset *)asset maxPixelSize:(NSUInteger)size
{
  NSParameterAssert(asset != nil);
  NSParameterAssert(size > 0);
  
  ALAssetRepresentation *rep = [asset defaultRepresentation];
  
  CGDataProviderDirectCallbacks callbacks = {
    .version = 0,
    .getBytePointer = NULL,
    .releaseBytePointer = NULL,
    .getBytesAtPosition = getAssetBytesCallback,
    .releaseInfo = releaseAssetCallback,
  };
  
  CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
  CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
  
  CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
    (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
    (NSString *)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithUnsignedInteger:size],
    (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
  });
  CFRelease(source);
  CFRelease(provider);
  
  if (!imageRef) {
    return nil;
  }
  
  UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
  
  CFRelease(imageRef);
  
  return toReturn;
}

- (void)showBehaviorImageTheNewWay:(NSURL *)imageUrl
{
  //  NSArray *assets = [[NSArray alloc] initWithObjects:self.behavior.imageUrl, nil];
  //  PHImageManager *manager = [PHImageManager defaultManager];
  //  PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:assets options:nil];
  CGFloat size = 350 * (1 + self.behavior.imageSize);
  //  [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
  //    NSLog(@"stuff: %@, %lu, %@",asset,(unsigned long)idx,stop?@"yes":@"no");
  //    [manager requestImageForAsset:asset targetSize:CGSizeMake(size, size) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
  //      NSLog(@"image: %@\ninfo: %@",result,info);
  //      self.actionImage = result;
  //      self.actionImageView.image = result;
  //      self.actionImageView.hidden = NO;
  //      if (asset.mediaType == PHAssetMediaTypeVideo) {
  //        self.playButton.hidden = self.finished;
  //      } else {
  //        self.playButton.hidden = YES;
  //        if (self.videoLayer && self.videoLayer.superlayer) {
  //          [self.videoLayer removeFromSuperlayer];
  //        }
  //      }
  //    }];
  //  }];
  
  NSArray *assets = [[NSArray alloc] initWithObjects:imageUrl, nil];
  PHImageManager *manager = [PHImageManager defaultManager];
  PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:assets options:nil];
  if (result.count > 0) {
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
      //      NSLog(@"stuff: %@, %lu, %@",asset,(unsigned long)idx,stop?@"yes":@"no");
      //      NSLog(@"phasset: %@", asset.localIdentifier);
      //      NSLog(@"alasset: %@", behavior.imageUrl);
      [manager requestImageForAsset:asset targetSize:CGSizeMake(size, size) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        //        NSLog(@"image: %@\ninfo: %@",result,info);
        self.actionImage = result;
        self.actionImageView.image = result;
        self.actionImageView.hidden = NO;
        if (asset.mediaType == PHAssetMediaTypeVideo) {
          self.playButton.hidden = self.finished;
        } else {
          self.playButton.hidden = YES;
          if (self.videoLayer && self.videoLayer.superlayer) {
            [self.videoLayer removeFromSuperlayer];
          }
        }
      }];
    }];
  } else {
    PHFetchResult *stream = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    [stream enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
      PHFetchResult *images = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
      [images enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        NSLog(@"stuff: %@, %lu, %@",asset,(unsigned long)idx,stop?@"yes":@"no");
        NSLog(@"phasset: %@", asset.localIdentifier);
        NSLog(@"alasset: %@", imageUrl);
        NSString *assetUrl = [imageUrl absoluteString];
        NSRange idLocation = [assetUrl rangeOfString:@"?id="];
        NSString *assetId = [assetUrl substringWithRange:NSMakeRange(idLocation.location+idLocation.length, 36)];
        if ([asset.localIdentifier hasPrefix:assetId]) {
          //          NSLog(@"yay: found it");
          *stop = YES;
          [manager requestImageForAsset:asset targetSize:CGSizeMake(size, size) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
            //            NSLog(@"image: %@\ninfo: %@",result,info);
            self.actionImage = result;
            self.actionImageView.image = result;
            self.actionImageView.hidden = NO;
            if (asset.mediaType == PHAssetMediaTypeVideo) {
              self.playButton.hidden = self.finished;
            } else {
              self.playButton.hidden = YES;
              if (self.videoLayer && self.videoLayer.superlayer) {
                [self.videoLayer removeFromSuperlayer];
              }
            }
          }];
        }
      }];
    }];
  }
}

- (void)findActionImage
{
  if (!self.behavior.imageUrl) {
    self.actionImageView.image = nil;
    self.playButton.hidden = YES;
    if (self.videoLayer && self.videoLayer.superlayer) {
      [self.videoLayer removeFromSuperlayer];
    }
    return;
  }
  NSURL *imageUrl = self.behavior.imageUrl;
  NSLog(@"imageUrl: %@", imageUrl);
  self.actionImageView.hidden = NO;
  
  if(NSClassFromString(@"PHImageManager")) {
    [self showBehaviorImageTheNewWay:imageUrl];
  } else {
    [self showBehaviorImageTheOldWay:imageUrl];
  }
}

- (void)setCellColor:(UIColor *)color
{
  self.colorView.backgroundColor = color;
  self.finishedCheck.textColor = color;
}

- (void)setCellFinished:(BOOL)finished
{
  self.finished = finished;
  self.finishedView.hidden = !finished;
  self.finishedCheck.hidden = !finished;
  if (!self.playButton.hidden) {
    self.playButton.hidden = finished;
  }
}

- (void)cellStoppedDisplaying
{
  self.playing = NO;
  self.actionImageView.hidden = NO;
  if (self.videoPlayer) {
    [self.videoPlayer pause];
  }
  if (self.videoLayer && self.videoLayer.superlayer) {
    [self.videoLayer removeFromSuperlayer];
  }
  [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
  [self.playButton setImage:[UIImage imageNamed:@"ForwardImage"] forState:UIControlStateNormal];
  //  [self.playButton setTitleColor:self.behavior.color forState:UIControlStateNormal];
  self.playButton.titleLabel.textColor = self.behavior.color;
}

- (IBAction)playVideo:(id)sender
{
  // if we were already playing a video, we've just stopped it and should not restart it.
  if (self.playing) {
    self.playing = NO;
//    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage imageNamed:@"ForwardImage"] forState:UIControlStateNormal];
    self.playButton.titleLabel.textColor = self.behavior.color;
    self.actionImageView.hidden = NO;
    [self.videoPlayer pause];
    if (self.videoLayer && self.videoLayer.superlayer) {
      [self.videoLayer removeFromSuperlayer];
    }
    return;
  }
  self.playing = YES;
//  [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
  [self.playButton setImage:[UIImage imageNamed:@"BlackBox"] forState:UIControlStateNormal];
  self.playButton.titleLabel.textColor = self.behavior.color;
  AVAsset *asset = [AVAsset assetWithURL:self.behavior.imageUrl];
  AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
  self.videoPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
  self.videoLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
  self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [self.videoLayer setFrame:self.actionImageView.frame];
  [self.layer addSublayer:self.videoLayer];
  [self.layer insertSublayer:self.videoLayer atIndex:0];
  [self.videoPlayer seekToTime:kCMTimeZero];
  [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    if (self.videoLayer && self.videoLayer.superlayer) {
      [self.videoLayer removeFromSuperlayer];
    }
    self.playing = NO;
//    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage imageNamed:@"ForwardImage"] forState:UIControlStateNormal];
    self.playButton.titleLabel.textColor = self.behavior.color;
    self.actionImageView.hidden = NO;
  }];
  self.actionImageView.hidden = YES;
  [self.videoPlayer play];
}

@end
