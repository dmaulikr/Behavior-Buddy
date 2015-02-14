#import <UIKit/UIKit.h>
#import "CAGCustomTypes.h"

@interface CAGActionTableViewCell : UITableViewCell

- (void)setCellInitiation:(CAGInitiation *)initiation;
- (void)setCellColor:(UIColor *)color;
- (void)setCellFinished:(BOOL)finished;
- (void)cellStoppedDisplaying;

@end
