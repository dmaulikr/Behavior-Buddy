#import <UIKit/UIKit.h>
#import "CAGCustomTypes.h"

@interface CAGTypeTableViewCell : UITableViewCell

- (void)setType:(CAGInitiationType *)type;
- (void)setTypeName:(NSString *)name;
- (void)setProgress:(CGFloat)progress;

@end
