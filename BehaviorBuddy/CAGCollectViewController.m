#import <QuartzCore/QuartzCore.h>
#import "CAGCollectViewController.h"
#import "CAGCustomTypes.h"
#import "CAGParticipantViewController.h"

#define ALERT_VIEW_NEW_SESSION          ((int) 100)
#define ALERT_VIEW_NEW_SETTING          ((int) 101)
#define ALERT_VIEW_INITIATIONS_REQUIRED ((int) 102)

#define TABLE_VIEW_CELL_EDIT_TAG        ((int) 200)
#define TABLE_VIEW_CELL_DELETE_TAG      ((int) 201)
#define TABLE_VIEW_CELL_LABEL_TAG       ((int) 202)
#define TABLE_VIEW_CELL_IMAGE_TAG       ((int) 203)

@interface CAGCollectViewController ()

@property NSArray *participants;
@property NSIndexPath *currentParticipant;
@property NSIndexPath *currentSession;
@property NSIndexPath *currentSetting;
@property IBOutlet UITableView *participantsTableView;
@property IBOutlet UITableView *sessionTableView;
@property IBOutlet UITableView *settingTableView;
@property IBOutlet UILabel *currentParticipantNameLabel;
@property CAGParticipantViewController *participantView;

@property NSMutableArray *behaviorCardViews;
@property UIView *greyCoverView;
@property UIColor *blueColor;

@end

@implementation CAGCollectViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.blueColor = [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:1.0];
  self.behaviorCardViews = [[NSMutableArray alloc] init];
  
  self.participantsTableView.layer.borderWidth = 0.5;
  self.participantsTableView.layer.borderColor = [self.blueColor CGColor];
  self.sessionTableView.layer.borderWidth = 0.5;
  self.sessionTableView.layer.borderColor = [self.blueColor CGColor];
  self.settingTableView.layer.borderWidth = 0.5;
  self.settingTableView.layer.borderColor = [self.blueColor CGColor];
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
  self.currentParticipant = [NSIndexPath indexPathForRow:[[info objectForKey:@"currentParticipant"] unsignedIntegerValue] inSection:0];
  self.currentSetting = nil;
  [self.participantsTableView reloadData];
  if (self.currentParticipant) {
    [self.participantsTableView selectRowAtIndexPath:self.currentParticipant animated:YES scrollPosition:UITableViewScrollPositionMiddle];
  }
  [self.sessionTableView reloadData];
  [self.settingTableView reloadData];
}

// gets the current participant
- (CAGParticipant *)gcp
{
  if (self.currentParticipant.row < self.participants.count) {
    return [self.participants objectAtIndex:self.currentParticipant.row];
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
  if (tableView == self.participantsTableView) {
    return 1;
  }
  else if (tableView == self.sessionTableView && self.currentParticipant) {
    return [self gcp].sessions.count + 1;
  }
  else if (tableView == self.settingTableView && self.currentSetting) {
    return [self gcp].initiationTypes.count + 2;
  }
  return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (tableView == _participantsTableView) {
    return @"Participants";
  }
  else if (tableView == _sessionTableView) {
    if (section < [self gcp].sessions.count) {
      return [[self gcp] getSessionAtIndex:section].name;
    }
    else {
      return @"New Session";
    }
  }
  else if (tableView == self.settingTableView) {
    if (section == 0) {
      return @"Completion Requirements";
    }
    else if (section <= [self gcp].initiationTypes.count) {
      return [NSString stringWithFormat:@"Available %@ Behaviors", [[self gcp] getInitiationTypeAtIndex:section - 1].name];
    }
    else if (section == [self gcp].initiationTypes.count + 1) {
      return @"Start";
    }
  }
  return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == _participantsTableView) {
    return self.participants.count;
  }
  else if (tableView == _sessionTableView) {
    if (section < [self gcp].sessions.count) {
      return [[self gcp] getSessionAtIndex:section].settings.count + 1;
    }
    else {
      return 1;
    }
  }
  else if (tableView == _settingTableView) {
    if (section == 0) {
      return [self gcp].initiationTypes.count;
    }
    else if (section <= [self gcp].initiationTypes.count) {
      return [[self gcp] getInitiationTypeAtIndex:section-1].initiations.count;
    }
    else if (section == [self gcp].initiationTypes.count + 1) {
      return 1;
    }
  }
  return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if (tableView == _participantsTableView) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"ParticipantCell" forIndexPath:indexPath];
    if (!_participants || !_participants.count) {
      cell.textLabel.text = @"No Participants!";
    }
    else {
      cell.textLabel.text = ((CAGParticipant *)[self.participants objectAtIndex:indexPath.row]).name;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  else if (tableView == _sessionTableView) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell" forIndexPath:indexPath];
    cell.userInteractionEnabled = YES;
    if (indexPath.section < [self gcp].sessions.count) {
      if (indexPath.row < [[self gcp] getSessionAtIndex:indexPath.section].settings.count) {
        CAGSetting *setting = [[[self gcp] getSessionAtIndex:indexPath.section] getSettingAtIndex:indexPath.row];
        cell.textLabel.text = setting.name;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = !setting.finished;
        if (setting.finished) {
          cell.backgroundColor = [UIColor lightGrayColor];
        }
        else {
          cell.backgroundColor = [UIColor clearColor];
        }
      }
      else {
        cell.textLabel.text = @"New Setting";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = [UIColor clearColor];
      }
    }
    else {
      cell.textLabel.text = @"New Session";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.backgroundColor = [UIColor clearColor];
    }
  }
  else if (tableView == _settingTableView && self.currentSetting) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell" forIndexPath:indexPath];
    if (indexPath.section == 0) {
      NSInteger numRequired = [[[[self gcp] getSessionAtIndex:self.currentSetting.section] getSettingAtIndex:self.currentSetting.row] getNumInitiationsRequiredForInitiationType:[[self gcp] getInitiationTypeAtIndex:indexPath.row]];
      NSInteger numAvailable = [[self gcp] getInitiationTypeAtIndex:indexPath.row].initiations.count;
      NSString *initiationTypeName = [[self gcp] getInitiationTypeAtIndex:indexPath.row].name;
      cell.textLabel.text = [NSString stringWithFormat:@"%lu/%lu %@ Behaviors", (long) numRequired, (long) numAvailable, initiationTypeName];
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if (indexPath.section <= [self gcp].initiationTypes.count) {
      long initiationType = indexPath.section - 1;
      cell.textLabel.text = [[[self gcp] getInitiationTypeAtIndex:initiationType] getInitiationAtIndex:indexPath.row].name;
      BOOL availability = [[[[self gcp] getSessionAtIndex:self.currentSetting.section] getSettingAtIndex:self.currentSetting.row] getAvailabilityForInitiationAtIndex:indexPath.row initiationType:[[self gcp] getInitiationTypeAtIndex:initiationType]];
      cell.accessoryType = availability ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if (indexPath.section == [self gcp].initiationTypes.count + 1) {
      cell.textLabel.text = @"Start!";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (tableView == _participantsTableView) {
    self.currentParticipant = indexPath;
    self.currentSetting = nil;
    [self.sessionTableView reloadData];
    [self.settingTableView reloadData];
  }
  else if (tableView == _sessionTableView) {
    if (indexPath.section < [self gcp].sessions.count) {
      if (indexPath.row < [[self gcp] getSessionAtIndex:indexPath.section].settings.count) {
        self.currentSetting = indexPath;
        [self.settingTableView reloadData];
      }
      else {
        self.currentSession = indexPath;
        UIAlertView *newSetting = [[UIAlertView alloc] initWithTitle:@"New Setting" message:@"What should this new setting be called?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
        newSetting.tag = ALERT_VIEW_NEW_SETTING;
        newSetting.alertViewStyle = UIAlertViewStylePlainTextInput;
        [newSetting show];
      }
    }
    else {
      UIAlertView *newSession = [[UIAlertView alloc] initWithTitle:@"New Session" message:@"What should this session be called?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
      newSession.tag = ALERT_VIEW_NEW_SESSION;
      newSession.alertViewStyle = UIAlertViewStylePlainTextInput;
      [newSession show];
    }
  }
  else if (tableView == _settingTableView) {
    if (indexPath.section == 0) {
      NSString *initiationTypeName = [[self gcp] getInitiationTypeAtIndex:indexPath.row].name;
      NSInteger numAvailable = [[self gcp] getInitiationTypeAtIndex:indexPath.row].initiations.count;
      UIAlertView *numInitiations = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ Behaviors", initiationTypeName] message:[NSString stringWithFormat:@"How many should be required in this setting? You can require between 0 and %lu to be performed.", (long) numAvailable] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
      numInitiations.tag = ALERT_VIEW_INITIATIONS_REQUIRED;
      numInitiations.alertViewStyle = UIAlertViewStylePlainTextInput;
      [numInitiations show];
    }
    else if (indexPath.section <= [self gcp].initiationTypes.count) {
      NSUInteger index = indexPath.row;
      CAGInitiationType *type = [[self gcp] getInitiationTypeAtIndex:indexPath.section-1];
      BOOL availability = ![[[[self gcp] getSessionAtIndex:self.currentSetting.section] getSettingAtIndex:self.currentSetting.row] getAvailabilityForInitiationAtIndex:index initiationType:type];
      [[[[self gcp] getSessionAtIndex:self.currentSetting.section] getSettingAtIndex:self.currentSetting.row] setAvailability:availability forInitiationAtIndex:index initiationType:type];
      [self.settingTableView reloadData];
    }
    else if (indexPath.section == [self gcp].initiationTypes.count + 1) {
      if (!self.participantView) {
        self.participantView = [[[NSBundle mainBundle] loadNibNamed:@"CAGParticipantViewController" owner:self options:nil] objectAtIndex:0];
      }
      [self.participantView prepareParticipant:[self gcp] withIndex:self.currentParticipant.row forSession:self.currentSetting.section inSetting:self.currentSetting.row];
      UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:self.participantView];
      navVC.modalPresentationStyle = UIModalPresentationFullScreen;
      [self presentViewController:navVC animated:YES completion:nil];
    }
  }
  else {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
  switch (alertView.tag) {
    case ALERT_VIEW_NEW_SESSION: {
      NSString *newSessionName = [alertView textFieldAtIndex:0].text;
      if (newSessionName && ![newSessionName isEqualToString:@""]) {
        [[self gcp] addSession:[[CAGSession alloc] initWithName:newSessionName]];
      }
      [self.sessionTableView reloadData];
      [self.settingTableView reloadData];
    }
      break;
      
    case ALERT_VIEW_NEW_SETTING: {
      NSString *newSettingName = [alertView textFieldAtIndex:0].text;
      if(newSettingName && ![newSettingName isEqualToString:@""]) {
        [[[self gcp] getSessionAtIndex:self.currentSession.section] addSetting:[[CAGSetting alloc] initWithName:newSettingName]];
      }
      self.currentSession = nil;
      [self.sessionTableView reloadData];
      [self.settingTableView reloadData];
    }
      break;
      
    case ALERT_VIEW_INITIATIONS_REQUIRED: {
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        NSInteger numRequired = [[alertView textFieldAtIndex:0].text integerValue];
        NSInteger numAvailable = [[self gcp] getInitiationTypeAtIndex:self.settingTableView.indexPathForSelectedRow.row].initiations.count;
        if (numRequired >= 0 && numRequired <= numAvailable) {
          [[[[self gcp] getSessionAtIndex:self.currentSetting.section] getSettingAtIndex:self.currentSetting.row] setNumInitiationsRequired:numRequired initiationType:[[self gcp] getInitiationTypeAtIndex:self.settingTableView.indexPathForSelectedRow.row]];
        }
        [self.settingTableView reloadData];
      }
      [self.settingTableView deselectRowAtIndexPath:self.settingTableView.indexPathForSelectedRow animated:YES];
    }
      break;
  }
}

- (IBAction)chooseParticipant:(id)sender
{
  NSLog(@"choosing new participant");
  self.currentParticipantNameLabel.text = [self gcp].name;
}

- (IBAction)startParticipantView:(id)sender
{
  NSLog(@"staring participant view");
}

@end
