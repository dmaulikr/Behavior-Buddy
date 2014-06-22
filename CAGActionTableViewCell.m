#import "CAGActionTableViewCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

@interface CAGActionTableViewCell ()

@property IBOutlet UILabel *actionNameLabel;
@property (nonatomic) UIImage *actionImage;
@property IBOutlet UIImageView *actionImageView;
@property CAGInitiation *initiation;
@property IBOutlet UIView *finishedView;
@property IBOutlet UILabel *finishedCheck;
@property IBOutlet UIView *colorView;

@end

@implementation CAGActionTableViewCell

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
}

- (void)setCellInitiation:(CAGInitiation *)initiation
{
  self.initiation = initiation;
  self.actionNameLabel.text = initiation.name;
  self.actionNameLabel.textColor = initiation.color;
  
  if (initiation.imageUrl) {
    [self findActionImage];
  }
  else {
    self.actionImageView.image = nil;
  }
}

-(void)findActionImage
{
  
  ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myAsset)
  {
    UIImage *image = [self thumbnailForAsset:myAsset maxPixelSize:350*(1+self.initiation.imageSize)];
    self.actionImage = image;
    self.actionImageView.image = image;
  };
  
  ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
  {
    NSLog(@"Image access error: %@", [myerror localizedDescription]);
  };
  
  ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
  [assetslibrary assetForURL:self.initiation.imageUrl
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

- (void)setCellColor:(UIColor *)color
{
  self.colorView.backgroundColor = color;
}

- (void)setCellFinished:(BOOL)finished
{
  self.finishedView.hidden = !finished;
  self.finishedCheck.hidden = !finished;
}

@end
