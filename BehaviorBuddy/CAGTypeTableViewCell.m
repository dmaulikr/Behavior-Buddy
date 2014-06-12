#import "CAGTypeTableViewCell.h"
#import "LDProgressView.h"

@interface CAGTypeTableViewCell ()

@property CAGInitiationType *initiationType;
@property (nonatomic) NSString *typeName;
@property IBOutlet UILabel *typeNameLabel;
@property LDProgressView *progressView;
@property UIColor *baseColor;
@property UIColor *background;
@property IBOutlet UIView *selectedView;
@property IBOutlet UILabel *finishedCheck;

@end

@implementation CAGTypeTableViewCell

- (void)awakeFromNib
{
  self.baseColor = [UIColor colorWithRed:0.00f green:0.50f blue:0.25f alpha:1.00f];
  self.background = [UIColor colorWithRed:0.00f green:0.75f blue:0.25f alpha:1.00f];
  
  CGRect progressViewFrame = self.frame;
  progressViewFrame.size.width -= 18;
  progressViewFrame.origin.y += 5;
  progressViewFrame.size.height -= 5;
  self.progressView = [[LDProgressView alloc] initWithFrame:progressViewFrame];
  self.progressView.progress = 0.5;
  self.progressView.color = self.baseColor;
  self.progressView.flat = @YES;
  self.progressView.animate = @NO;
  self.progressView.showText = @NO;
  self.progressView.showStroke = @NO;
  self.progressView.progressInset = @5;
  self.progressView.showBackground = @YES;
  self.progressView.background = self.background;
  self.progressView.showBackgroundInnerShadow = @NO;
  self.progressView.outerStrokeWidth = @0;
  self.progressView.type = LDProgressSolid;
  [self insertSubview:self.progressView belowSubview:self.typeNameLabel];
}

- (void)setType:(CAGInitiationType *)type
{
  self.initiationType = type;
  self.progressView.background = type.color;
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
  [type.color getRed:&red green:&green blue:&blue alpha:&alpha];
  if (red == 0 && green == 0 && blue == 0) {
    red = 0.5;
    green = 0.5;
    blue = 0.5;
  } else {
    red *= 0.5;
    green *= 0.5;
    blue *= 0.5;
  }
  self.progressView.color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
  self.selectedView.backgroundColor = type.color;
  [self setTypeName:type.name];
}

- (void)setTypeName:(NSString *)name
{
  _typeName = name;
  self.typeNameLabel.textColor = [UIColor whiteColor];
  self.typeNameLabel.text = name;
}

- (void)setProgress:(CGFloat)progress
{
  if (progress < 0) {
    progress = 0;
  }
  else if (progress > 1) {
    progress = 1;
  }
  if (progress == 1) {
    self.finishedCheck.hidden = NO;
    self.selectedView.alpha = 0.5;
    self.typeNameLabel.alpha = 0.5;
    self.progressView.alpha = 0.5;
  }
  else {
    self.finishedCheck.hidden = YES;
    self.selectedView.alpha = 1;
    self.typeNameLabel.alpha = 1;
    self.progressView.alpha = 1;
  }
  self.progressView.progress = progress;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
  [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  self.selectedView.hidden = !selected;
}

@end
