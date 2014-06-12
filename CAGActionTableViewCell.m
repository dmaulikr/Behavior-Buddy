#import "CAGActionTableViewCell.h"
#import <AssetsLibrary/AssetsLibrary.h>

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
  
  ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
  {
    ALAssetRepresentation *rep = [myasset defaultRepresentation];
    CGImageRef iref = [rep fullResolutionImage];
    if (iref) {
      self.actionImage = [UIImage imageWithCGImage:iref];
      self.actionImageView.image = self.actionImage;
    }
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
