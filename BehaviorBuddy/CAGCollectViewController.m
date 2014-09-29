#import <QuartzCore/QuartzCore.h>
#import "CAGCollectViewController.h"
#import "CAGCustomTypes.h"
#import "CAGParticipantViewController.h"

#define ALERT_VIEW_NEW_SESSION          ((int) 100)
#define ALERT_VIEW_NEW_SETTING          ((int) 101)
#define ALERT_VIEW_INITIATIONS_REQUIRED ((int) 102)
#define ALERT_VIEW_EDIT_SESSION         ((int) 103)
#define ALERT_VIEW_DELETE_SESSION       ((int) 104)
#define ALERT_VIEW_EDIT_SETTING         ((int) 105)
#define ALERT_VIEW_DELETE_SETTING       ((int) 106)
#define ALERT_VIEW_REQUIRE_BEHAVIORS    ((int) 107)

#define TABLE_VIEW_CELL_EDIT_TAG        ((int) 200)
#define TABLE_VIEW_CELL_DELETE_TAG      ((int) 201)
#define TABLE_VIEW_CELL_LABEL_TAG       ((int) 202)
#define TABLE_VIEW_CELL_IMAGE_TAG       ((int) 203)
#define TABLE_VIEW_CELL_LABEL2_TAG      ((int) 204)

#define NO_CURRENT NSUIntegerMax

@interface CAGCollectViewController ()

@property NSArray *participants;
@property (nonatomic) NSUInteger currentParticipant;
@property NSUInteger currentSession;
@property (nonatomic) NSUInteger currentSetting;
@property NSUInteger selectedBehaviorType;
@property IBOutlet UITableView *sessionTableView;
@property IBOutlet UITableView *settingTableView;
@property IBOutlet UITableView *reqsTableView;
@property IBOutlet UILabel *currentParticipantNameLabel;
@property IBOutlet UIButton *startButton;
@property CAGParticipantViewController *participantView;
@property CAGChooseParticipantViewController *participantPicker;

@property NSMutableArray *behaviorCardViews;
@property UIView *greyCoverView;
@property UIColor *blueColor;
@property UIImage *checkImage;
@property UIImage *xImage;

@end

@implementation CAGCollectViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.blueColor = [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:1.0];
  self.behaviorCardViews = [[NSMutableArray alloc] init];
  
  self.sessionTableView.layer.borderWidth = 0.5;
  self.sessionTableView.layer.borderColor = [self.blueColor CGColor];
  self.settingTableView.layer.borderWidth = 0.5;
  self.settingTableView.layer.borderColor = [self.blueColor CGColor];
  self.reqsTableView.layer.borderWidth = 0.5;
  self.reqsTableView.layer.borderColor = [self.blueColor CGColor];
  
  self.selectedBehaviorType = NO_CURRENT;
  self.checkImage = [UIImage imageNamed:@"CheckImage.png"];
  self.xImage = [UIImage imageNamed:@"XImage.png"];
  NSLog(@"images: check: %f\nx: %f", self.checkImage.size.width, self.xImage.size.height);
}

- (void)viewDidAppear:(BOOL)animated
{
  NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
  NSData *participantsData = [info objectForKey:@"participants"];
  NSMutableArray *participants = [NSKeyedUnarchiver unarchiveObjectWithData:participantsData];
  if (participants) {
    self.participants = participants;
  }
  else {
    self.participants = [[NSMutableArray alloc] init];
  }
  self.currentParticipant = [[info objectForKey:@"currentParticipant"] unsignedIntegerValue];
  self.currentSession = NO_CURRENT;
  self.currentSetting = NO_CURRENT;
  [self.sessionTableView reloadData];
  [self.settingTableView reloadData];
  [self.reqsTableView reloadData];
}

- (void)setCurrentParticipant:(NSUInteger)currentParticipant
{
  _currentParticipant = currentParticipant;
  self.currentParticipantNameLabel.text = [self gcp].name;
}

- (void)setCurrentSetting:(NSUInteger)currentSetting
{
  _currentSetting = currentSetting;
  self.startButton.hidden = currentSetting == NO_CURRENT;
}

// gets the current participant
- (CAGParticipant *)gcp
{
  if (self.currentParticipant != NO_CURRENT && self.currentParticipant < self.participants.count) {
    return [self.participants objectAtIndex:self.currentParticipant];
  }
  return nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
  NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.participants];
  [info setObject:data forKey:@"participants"];
  [info synchronize];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (tableView == self.sessionTableView) {
    return 2;
  }
  else if (tableView == self.settingTableView && self.currentSession != NO_CURRENT) {
    return 2;
  }
  else if (tableView == self.reqsTableView && self.currentSetting != NO_CURRENT) {
    return [self gcp].initiationTypes.count + 1;
  }
  return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (tableView == self.sessionTableView) {
    if (section == 0) {
      return @"Sessions";
    }
  }
  else if (tableView == self.settingTableView) {
    if (section == 0) {
      return @"Settings";
    }
  }
  else if (tableView == self.reqsTableView) {
    if (section == 0) {
      return @"Required Behaviors";
    }
    else if (section <= [self gcp].initiationTypes.count) {
      return [NSString stringWithFormat:@"%@ Options", [[self gcp] getInitiationTypeAtIndex:section - 1].name];
    }
  }
  return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.sessionTableView) {
    if (section == 0) {
      return [self gcp].sessions.count;
    }
    else {
      return 1;
    }
  }
  else if (tableView == self.settingTableView && self.currentSession != NO_CURRENT) {
    if (section == 0) {
      return [[self gcp] getSessionAtIndex:self.currentSession].settings.count;
    }
    else {
      return 1;
    }
  }
  else if (tableView == self.reqsTableView && self.currentSetting != NO_CURRENT) {
    if (section == 0) {
      return [self gcp].initiationTypes.count;
    }
    else if (section <= [self gcp].initiationTypes.count) {
      return [[self gcp] getInitiationTypeAtIndex:section-1].initiations.count;
    }
  }
  return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if (tableView == self.sessionTableView) {
    if (indexPath.section == 0) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell" forIndexPath:indexPath];
    }
    else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"NewSessionCell" forIndexPath:indexPath];
    }
  }
  else if (tableView == self.settingTableView) {
    if (indexPath.section == 0) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell" forIndexPath:indexPath];
    }
    else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"NewSettingCell" forIndexPath:indexPath];
    }
  }
  else if (tableView == self.reqsTableView) {
    if (indexPath.section == 0) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"RequiredBehaviorTypeCell" forIndexPath:indexPath];
    }
    else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"BehaviorVisibilityCell" forIndexPath:indexPath];
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.sessionTableView) {
    if (indexPath.section == 0) {
      UILabel *label = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
      UIButton *edit = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
      UIButton *delete = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
      
      label.text = [[self gcp] getSessionAtIndex:indexPath.row].name;
      bool selected = indexPath.row == self.currentSession;
      edit.hidden = !selected;
      delete.hidden = !selected;
      cell.backgroundColor = selected ? self.blueColor : [UIColor whiteColor];
    }
  }
  else if (tableView == self.settingTableView) {
    if (indexPath.section == 0) {
      UILabel *label = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
      UIButton *edit = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
      UIButton *delete = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
      
      CAGSetting *setting = [[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:indexPath.row];
      if (setting.finished) {
        label.text = [NSString stringWithFormat:@"(finished) %@", setting.name];
        label.textColor = [UIColor lightGrayColor];
        cell.userInteractionEnabled = NO;
      }
      else {
        label.text = setting.name;
        label.textColor = [UIColor blackColor];
        cell.userInteractionEnabled = YES;
      }
      bool selected = indexPath.row == self.currentSetting;
      edit.hidden = !selected;
      delete.hidden = !selected;
      cell.backgroundColor = selected ? self.blueColor : [UIColor whiteColor];
    }
  }
  else if (tableView == self.reqsTableView) {
    if (indexPath.section == 0) {
      UILabel *nameLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
      UILabel *requiredLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL2_TAG];
      NSUInteger numRequired = [[[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting] getNumInitiationsRequiredForInitiationType:[[self gcp] getInitiationTypeAtIndex:indexPath.row]];
      NSUInteger numAvailable = [[self gcp] getInitiationTypeAtIndex:indexPath.row].initiations.count;
      NSString *initiationTypeName = [[self gcp] getInitiationTypeAtIndex:indexPath.row].name;
      
      nameLabel.text = initiationTypeName;
      requiredLabel.text = [NSString stringWithFormat:@"(%lu/%lu Required)", (unsigned long)numRequired, (unsigned long)numAvailable];
      
//      if (self.currentSettingFinished) {
//        cell.userInteractionEnabled = nameLabel.enabled = requiredLabel.enabled = NO;
//      }
//      else {
//        cell.userInteractionEnabled = nameLabel.enabled = requiredLabel.enabled = YES;
//      }
    }
    else if (indexPath.section <= [self gcp].initiationTypes.count) {
      NSUInteger initiationType = indexPath.section - 1;
      UILabel *label = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
      UIImageView *image = (UIImageView *)[cell viewWithTag:TABLE_VIEW_CELL_IMAGE_TAG];
      BOOL available = [[[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting] getAvailabilityForInitiationAtIndex:indexPath.row initiationType:[[self gcp] getInitiationTypeAtIndex:initiationType]];
      label.text = [[[self gcp] getInitiationTypeAtIndex:initiationType] getInitiationAtIndex:indexPath.row].name;
      if (available) {
        image.image = self.checkImage;
      }
      else {
        image.image = self.xImage;
      }
      
//      if (self.currentSettingFinished) {
//        cell.userInteractionEnabled = label.enabled = NO;
//      }
//      else {
//        cell.userInteractionEnabled = label.enabled = YES;
//      }
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (tableView == self.sessionTableView) {
    if (indexPath.section == 0) {
      self.currentSession = indexPath.row;
      self.currentSetting = NO_CURRENT;
      [self.sessionTableView reloadData];
      [self.settingTableView reloadData];
      [self.reqsTableView reloadData];
    }
    else {
      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
      [dateFormat setDateFormat:@"MM/dd/yyyy"];
      NSString *newSessionSuggestedName = [dateFormat stringFromDate:[[NSDate alloc] init]];
      
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Session" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      alert.tag = ALERT_VIEW_NEW_SESSION;
      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [alert textFieldAtIndex:0].text = newSessionSuggestedName;
      [alert show];
    }
  }
  else if (tableView == self.settingTableView) {
    if (indexPath.section == 0) {
      self.currentSetting = indexPath.row;
      [self.settingTableView reloadData];
      [self.reqsTableView reloadData];
    }
    else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Setting" message:@"Where is this setting?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      alert.tag = ALERT_VIEW_NEW_SETTING;
      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [alert show];
    }
  }
  else if (tableView == self.reqsTableView) {
    if (indexPath.section == 0) {
      self.selectedBehaviorType = indexPath.row;
      CAGInitiationType *type = [[self gcp] getInitiationTypeAtIndex:indexPath.row];
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Required %@ Behaviors", type.name] message:[NSString stringWithFormat:@"You can require between 0 and %lu behaviors of this type", (unsigned long)type.initiations.count] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
      alert.tag = ALERT_VIEW_REQUIRE_BEHAVIORS;
      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [alert show];
    }
    else {
      CAGInitiationType *behaviorType = [[self gcp] getInitiationTypeAtIndex:indexPath.section-1];
      bool available = ![[[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting] getAvailabilityForInitiationAtIndex:indexPath.row initiationType:behaviorType];
      [[[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting] setAvailability:available forInitiationAtIndex:indexPath.row initiationType:behaviorType];
      [self.reqsTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
  }
}

- (void)recordBehaviorViewDiscard:(CAGRecordBehaviorView *)rbView
{
}
- (void)recordBehaviorViewPreviousBehavior:(CAGRecordBehaviorView *)rbView
{
}
- (void)recordBehaviorView:(CAGRecordBehaviorView *)rbView nextBehavior:(NSIndexPath *)nextBehavior
{
}
- (void)recordBehaviorViewDone:(CAGRecordBehaviorView *)rbView
{
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // pressed cancel
  if (buttonIndex == 0) {
    return;
  }
  switch (alertView.tag) {
    case ALERT_VIEW_NEW_SESSION: {
      NSString *newSessionName = [alertView textFieldAtIndex:0].text;
      if (newSessionName && ![newSessionName isEqualToString:@""]) {
        [[self gcp] addSession:[[CAGSession alloc] initWithName:newSessionName]];
      }
      self.currentSession = [self gcp].sessions.count-1;
      [self.sessionTableView reloadData];
      [self.settingTableView reloadData];
      [self.reqsTableView reloadData];
    }
      break;
      
    case ALERT_VIEW_NEW_SETTING: {
      NSString *newSettingName = [alertView textFieldAtIndex:0].text;
      if(newSettingName && ![newSettingName isEqualToString:@""]) {
        [[[self gcp] getSessionAtIndex:self.currentSession] addSetting:[[CAGSetting alloc] initWithName:newSettingName]];
      }
      self.currentSetting = [[self gcp] getSessionAtIndex:self.currentSession].settings.count-1;
      [self.settingTableView reloadData];
      [self.reqsTableView reloadData];
    }
      break;
      
    case ALERT_VIEW_EDIT_SESSION: {
      NSString *sessionName = [alertView textFieldAtIndex:0].text;
      if (sessionName && ![sessionName isEqualToString:@""]) {
        [[self gcp] getSessionAtIndex:self.currentSession].name = sessionName;
      }
      [self.sessionTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentSession inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    }
      break;
      
    case ALERT_VIEW_DELETE_SESSION: {
      [[self gcp] removeSessionAtIndex:self.currentSession];
      [self.sessionTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentSession inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
      self.currentSession = NO_CURRENT;
      self.currentSetting = NO_CURRENT;
      [self.settingTableView reloadData];
      [self.reqsTableView reloadData];
    }
      break;
      
    case ALERT_VIEW_EDIT_SETTING: {
      NSString *settingName = [alertView textFieldAtIndex:0].text;
      if (settingName && ![settingName isEqualToString:@""]) {
        [[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting].name = settingName;
      }
      [self.settingTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentSetting inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    }
      break;
      
    case ALERT_VIEW_DELETE_SETTING: {
      [[[self gcp] getSessionAtIndex:self.currentSession] removeSettingAtIndex:self.currentSetting];
      [self.settingTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentSetting inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
      self.currentSetting = NO_CURRENT;
      [self.reqsTableView reloadData];
    }
      break;
      
    case ALERT_VIEW_REQUIRE_BEHAVIORS: {
      if (![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        NSInteger numRequired = [[alertView textFieldAtIndex:0].text integerValue];
        NSInteger numAvailable = [[self gcp] getInitiationTypeAtIndex:self.selectedBehaviorType].initiations.count;
        numRequired = MIN(MAX(0, numRequired),numAvailable);
        if (numRequired >= 0 && numRequired <= numAvailable) {
          [[[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting] setNumInitiationsRequired:numRequired initiationType:[[self gcp] getInitiationTypeAtIndex:self.selectedBehaviorType]];
        }
        self.selectedBehaviorType = NO_CURRENT;
        [self.reqsTableView reloadData];
      }
    }
      break;
  }
}

- (IBAction)chooseParticipant:(id)sender
{
  NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.participants];
  [info setObject:data forKey:@"participants"];
  [info synchronize];
  
  if (!self.participantPicker) {
    self.participantPicker = [[CAGChooseParticipantViewController alloc] init];
  }
  self.participantPicker.delegate = self;
  self.participantPicker.title = @"Choose a Participant";
  UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:self.participantPicker];
  navVC.modalPresentationStyle = UIModalPresentationFormSheet;
  navVC.navigationBar.backgroundColor = self.blueColor;
  [self presentViewController:navVC animated:YES completion:nil];
}

- (void)chooseParticipantViewController:(CAGChooseParticipantViewController *)controller newListOfParticipants:(NSMutableArray *)participants choosenParticipant:(NSUInteger)participant
{
  NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:participants];
  [info setObject:data forKey:@"participants"];
  [info setObject:[NSNumber numberWithUnsignedInteger:participant] forKey:@"currentParticipant"];
  [info synchronize];
  NSLog(@"chose: %lu", (unsigned long)participant);
  self.participants = participants;
  self.currentParticipant = participant;
  self.currentSession = NO_CURRENT;
  self.currentSetting = NO_CURRENT;
  [self.sessionTableView reloadData];
  [self.settingTableView reloadData];
  [self.reqsTableView reloadData];
  [self.participantPicker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startParticipantView:(id)sender
{
  if (!self.participantView) {
    self.participantView = [[[NSBundle mainBundle] loadNibNamed:@"CAGParticipantViewController" owner:self options:nil] objectAtIndex:0];
  }
  [self.participantView prepareParticipant:[self gcp] withIndex:self.currentParticipant forSession:self.currentSession inSetting:self.currentSetting];
  UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:self.participantView];
  navVC.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:navVC animated:YES completion:nil];
  NSLog(@"staring participant view");
}

- (IBAction)editSession:(id)sender
{
  NSString *title = [NSString stringWithFormat:@"Rename %@?", [[self gcp] getSessionAtIndex:self.currentSession].name];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
  alert.tag = ALERT_VIEW_EDIT_SESSION;
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alert show];
}

- (IBAction)deleteSession:(id)sender
{
  NSString *title = [NSString stringWithFormat:@"Delete %@?", [[self gcp] getSessionAtIndex:self.currentSession].name];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"CAUTION\nThis will delete all settings and participant data in this session" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
  alert.tag = ALERT_VIEW_DELETE_SESSION;
  alert.alertViewStyle = UIAlertViewStyleDefault;
  [alert show];
}

- (IBAction)editSetting:(id)sender
{
  NSString *title = [NSString stringWithFormat:@"Rename %@?", [[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting].name];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
  alert.tag = ALERT_VIEW_EDIT_SETTING;
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alert show];
}

- (IBAction)deleteSetting:(id)sender
{
  NSString *title = [NSString stringWithFormat:@"Delete %@?", [[[self gcp] getSessionAtIndex:self.currentSession] getSettingAtIndex:self.currentSetting].name];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"CAUTION\nThis will delete all custom requirements for this setting" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
  alert.tag = ALERT_VIEW_DELETE_SETTING;
  alert.alertViewStyle = UIAlertViewStyleDefault;
  [alert show];
}

@end
