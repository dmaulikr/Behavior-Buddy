#import <UIKit/UIKit.h>

@protocol CAGParticipantResponsesViewDelegate;

@interface CAGParticipantResponsesView : UIView <UITableViewDataSource, UITableViewDelegate>

@property NSString *actionName;
@property IBOutlet UILabel *actionNameLabel;
@property IBOutlet UITableView *responsesTableView;
@property NSArray *responses;
@property id<CAGParticipantResponsesViewDelegate> delegate;

- (void)showResponses:(NSArray *)responses forActionName:(NSString *)actionName withDelegate:(id<CAGParticipantResponsesViewDelegate>)delegate;

@end

@protocol CAGParticipantResponsesViewDelegate <NSObject>

- (void)participantResponsesViewDone:(CAGParticipantResponsesView *)view;

@end