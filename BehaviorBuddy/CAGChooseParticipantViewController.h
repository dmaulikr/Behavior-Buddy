#import <UIKit/UIKit.h>

@protocol CAGChooseParticipantDelegate;

@interface CAGChooseParticipantViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property id<CAGChooseParticipantDelegate> delegate;

@end

@protocol CAGChooseParticipantDelegate <NSObject>

- (void)chooseParticipantViewController:(CAGChooseParticipantViewController *)controller newListOfParticipants:(NSMutableArray *)participants choosenParticipant:(NSUInteger)participant;

@end
