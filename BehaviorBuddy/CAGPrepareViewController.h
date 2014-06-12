#import <UIKit/UIKit.h>
#import "CAGNewBehaviorView.h"
#import "NEOColorPickerViewController.h"
#import "CAGChooseParticipantViewController.h"

@interface CAGPrepareViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIActionSheetDelegate, NEOColorPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CAGChooseParticipantDelegate>

@property IBOutlet UITableView *behaviorTypeTableView;
@property IBOutlet UITableView *behaviorTableView;
@property IBOutlet UITableView *responseTableView;
@property IBOutlet UIView *behaviorImageContainer;
@property IBOutlet UILabel *behaviorImageName;
@property IBOutlet UIImageView *behaviorImage;
@property IBOutlet UISegmentedControl *behaviorImageSizeControl;
@property IBOutlet UIView *behaviorImageContainerBackground;
@property IBOutlet UILabel *currentParticipantNameLabel;

@end
