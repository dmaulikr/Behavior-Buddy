#import "CAGActionTableViewCell.h"
#import <ImageIO/ImageIO.h>

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

-(void)findActionImage
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
