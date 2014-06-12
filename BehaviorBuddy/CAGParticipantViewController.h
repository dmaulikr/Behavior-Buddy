#import <UIKit/UIKit.h>
#import "CAGCustomTypes.h"
#import "CAGParticipantResponsesView.h"

@interface CAGParticipantViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CAGParticipantResponsesViewDelegate>

- (void)prepareParticipant:(CAGParticipant *)participant withIndex:(NSInteger)index forSession:(NSInteger)session inSetting:(NSInteger)setting;

@end
