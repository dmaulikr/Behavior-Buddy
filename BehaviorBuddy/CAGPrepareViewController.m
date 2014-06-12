#import "CAGPrepareViewController.h"
#import "CAGNewBehaviorView.h"
#import <QuartzCore/QuartzCore.h>
#import "CAGCustomTypes.h"

/***
 Using Color Picker from https://github.com/kartech/colorpicker
 ***/

#define ALERT_VIEW_NEW_PARTICIPANT      ((int) 100)
#define ALERT_VIEW_NEW_INITIATION_TYPE  ((int) 101)
#define ALERT_VIEW_NEW_INITIATION       ((int) 102)
#define ALERT_VIEW_RENAME_INITIATION    ((int) 103)
#define ALERT_VIEW_NEW_RESPONSE         ((int) 104)
#define ALERT_VIEW_DELETE_RESPONSE      ((int) 105)
#define ALERT_VIEW_MODIFY_RESPONSE      ((int) 106)
#define ALERT_VIEW_DELETE_PARTICIPANT   ((int) 107)
#define ALERT_VIEW_DELETE_BEHAVIOR_TYPE ((int) 108)
#define ALERT_VIEW_DELETE_BEHAVIOR      ((int) 109)
#define ALERT_VIEW_SET_PASSWORD         ((int) 110)
#define ALERT_VIEW_SET_PASSWORD_CONFIRM ((int) 111)
#define ALERT_VIEW_LOCK_APP             ((int) 112)
#define TABLE_VIEW_CELL_EDIT_TAG        ((int) 113)
#define TABLE_VIEW_CELL_COLOR_TAG       ((int) 114)
#define TABLE_VIEW_CELL_DELETE_TAG      ((int) 115)
#define TABLE_VIEW_CELL_LABEL_TAG       ((int) 116)
#define ALERT_VIEW_RENAME_BEHAVIOR_TYPE ((int) 117)

#define NO_CURRENT NSUIntegerMax

@interface CAGPrepareViewController ()

@property (nonatomic) NSUInteger currentParticipant;
@property (nonatomic) NSUInteger currentBehavior;
@property NSUInteger currentBehaviorType;
@property NSUInteger currentResponse;
@property UIView *greyCoverView;
@property NSMutableArray *participants;
@property CAGChooseParticipantViewController *participantPicker;
@property NEOColorPickerViewController *colorPicker;
@property UIPopoverController *imagePicker;
@property BOOL choosingColor;
@property BOOL choosingTypeColor;
@property UIColor *blueColor;

@end

@implementation CAGPrepareViewController

- (void)setCurrentBehavior:(NSUInteger)currentBehavior
{
  _currentBehavior = currentBehavior;
  if (currentBehavior == NO_CURRENT) {
    self.behaviorImageContainer.hidden = YES;
  }
  else {
    self.behaviorImageContainer.hidden = NO;
  }
}

- (void)setCurrentParticipant:(NSUInteger)currentParticipant
{
  _currentParticipant = currentParticipant;
  self.currentParticipantNameLabel.text = [self gcp].name;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.blueColor = [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:1.0];
  
  self.greyCoverView = [[UIView alloc] initWithFrame:self.view.frame];
  [self.greyCoverView setBackgroundColor:[UIColor blackColor]];
  self.greyCoverView.alpha = 0.0;
  
  self.behaviorTypeTableView.layer.borderWidth = 0.5;
  self.behaviorTypeTableView.layer.borderColor = [self.blueColor CGColor];
  self.behaviorTableView.layer.borderWidth = 0.5;
  self.behaviorTableView.layer.borderColor = [self.blueColor CGColor];
  self.responseTableView.layer.borderWidth = 0.5;
  self.responseTableView.layer.borderColor = [self.blueColor CGColor];
  self.behaviorImageContainerBackground.layer.borderWidth = 0.5;
  self.behaviorImageContainerBackground.layer.borderColor = [self.blueColor CGColor];
  
  self.currentParticipant = NO_CURRENT;
}

- (void)viewDidAppear:(BOOL)animated
{
  if (self.choosingColor) {
    self.choosingColor = NO;
    self.choosingTypeColor = NO;
  }
  else {
    NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
    NSData *participantsData = [info objectForKey:@"participants"];
    NSMutableArray *participants = [NSKeyedUnarchiver unarchiveObjectWithData:participantsData];
    if (participants) {
      self.participants = participants;
    }
    else {
      self.participants = [[NSMutableArray alloc] init];
    }
    if ([info valueForKey:@"currentParticipant"]) {
      self.currentParticipant = [[info objectForKey:@"currentParticipant"] unsignedIntegerValue];
    }
    else {
      [self chooseParticipant:nil];
    }
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.participants];
  [info setObject:data forKey:@"participants"];
  [info synchronize];
}

- (void)newParticipant:(NSString *)name
{
  self.currentBehavior = NO_CURRENT;
  [self.participants addObject:[[CAGParticipant alloc] initWithName:name]];
  self.currentParticipant = self.participants.count - 1;
  [self.behaviorTypeTableView reloadData];
  [self.behaviorTableView reloadData];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentParticipant inSection:0];
  [self.behaviorTypeTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
  [self.responseTableView reloadData];
}

- (void)newBehaviorType:(NSString *)name
{
  self.currentBehavior = NO_CURRENT;
  
  NSMutableDictionary *newType = [[NSMutableDictionary alloc] init];
  [newType setObject:name forKey:@"name"];
  [newType setObject:[[NSMutableArray alloc] init] forKey:@"behaviors"];

  [self.behaviorTableView reloadData];
  [self.responseTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

// gets the current participant
- (CAGParticipant *)gcp
{
  if (self.currentParticipant != NO_CURRENT && self.currentParticipant < self.participants.count) {
    return [self.participants objectAtIndex:self.currentParticipant];
  }
  return nil;
}

// returns "word" in the format "a word" with "an" in front of words that start with vowels
- (NSString *)n:(NSString *)word
{
  NSString *formatString;
  if (word.length && ([word characterAtIndex:0] == 'a' ||
                      [word characterAtIndex:0] == 'e' ||
                      [word characterAtIndex:0] == 'i' ||
                      [word characterAtIndex:0] == 'o' ||
                      [word characterAtIndex:0] == 'u' ||
                      [word characterAtIndex:0] == 'A' ||
                      [word characterAtIndex:0] == 'E' ||
                      [word characterAtIndex:0] == 'I' ||
                      [word characterAtIndex:0] == 'O' ||
                      [word characterAtIndex:0] == 'U')) {
    formatString = @"an %@";
  } else {
    formatString = @"a %@";
  }
  return [NSString stringWithFormat:formatString, word];
}

- (BOOL)showDetails
{
  return self.currentBehavior != NO_CURRENT;
}

#pragma mark - Table View Delegate and Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (tableView == self.behaviorTypeTableView) {
    return 2;
  }
  else if (tableView == self.behaviorTableView) {
    if (self.currentBehaviorType != NO_CURRENT) {
      return 2;
    }
  }
  else if (tableView == self.responseTableView) {
    if (self.currentBehavior != NO_CURRENT) {
      return 2;
    }
  }
  return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (tableView == self.behaviorTypeTableView) {
    if (section == 0) {
      return @"Behavior Types";
    }
//    if (section == 1) {
//      return @"New Participant";
//    }
//    if (section == 2) {
//      return @"Security";
//    }
  }
  else if (tableView == self.behaviorTableView) {
    if (section == 0) {
      return [NSString stringWithFormat:@"%@ Behaviors", [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].name];
    }
//    else if (section == [self gcp].initiationTypes.count) {
//      return @"New Behavior Type";
//    }
//    else {
//      return @"Delete Participant";
//    }
  }
  else if (tableView == self.responseTableView) {
    if (section == 0) {
      return [NSString stringWithFormat:@"%@ Responses", [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].name];
//      else if (section == 1) {
//        return @"Modify Behavior";
//      }
    }
  }
  return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.behaviorTypeTableView) {
    if (section) {
      return 1;
    }
    NSLog(@"current participant %@", [self gcp]);
    return [self gcp].initiationTypes.count;
//    if (section == 0) {
//      return self.participants.count;
//    }
//    if (section == 1) {
//      return 1;
//    }
//    if (section == 2) {
//      return 2;
//    }
  }
  else if (tableView == self.behaviorTableView) {
    if (section) {
      return 1;
    }
    return [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].initiations.count;
//    if (section < [self gcp].initiationTypes.count) {
//      return [[self gcp] getInitiationTypeAtIndex:section].initiations.count;
//    }
//    return 1;
  }
  else if (tableView == self.responseTableView) {
    if (section) {
      return 1;
    }
//    if (section == 0) {
      return [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses.count;
//    }
//    else if (section == 1) {
//      return 4;
//    }
  }
  return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if (tableView == self.behaviorTypeTableView) {
    if (indexPath.section) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"NewBehaviorTypeCell" forIndexPath:indexPath];
    }
    else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"BehaviorTypeCell" forIndexPath:indexPath];
    }
  }
  if (tableView == self.behaviorTableView) {
    if (indexPath.section) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"NewBehaviorCell"];
    }
    else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"BehaviorCell" forIndexPath:indexPath];
    }
  }
  if (tableView == self.responseTableView) {
    if (indexPath.section) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"NewResponseCell"];
    }
    else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"ResponseCell" forIndexPath:indexPath];
    }
  }
  return cell;
//  if (tableView == self.behaviorTypeTableView) {
//    if (indexPath.section) {
//      cell = [tableView dequeueReusableCellWithIdentifier:@"NewBehaviorTypeCell"];
//      return cell;
//    }
//    cell = [tableView dequeueReusableCellWithIdentifier:@"BehaviorTypeCell" forIndexPath:indexPath];
//    UILabel *textLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
////    if (indexPath.section == 0) {
//      if (indexPath.row < [self gcp].initiationTypes.count) {
//        textLabel.text = [[self gcp] getInitiationTypeAtIndex:indexPath.row].name;
//      }
//    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
//    UIButton *colorButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_COLOR_TAG];
//    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
//    if (self.currentBehaviorType == indexPath.row) {
//      editButton.hidden = NO;
//      colorButton.hidden = NO;
//      deleteButton.hidden = NO;
//      cell.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
//    }
//    else {
//      editButton.hidden = YES;
//      colorButton.hidden = YES;
//      deleteButton.hidden = YES;
//      cell.backgroundColor = [UIColor whiteColor];
//    }
////      cell.accessoryType = UITableViewCellAccessoryNone;
////    }
////    if (indexPath.section == 1) {
////      textLabel.text = @"Add a Participant";
////      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////    }
////    if (indexPath.section == 2) {
////      if (indexPath.row == 0) {
////        textLabel.text = @"Set Password";
////        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      }
////      if (indexPath.row == 1) {
////        textLabel.text = @"Lock App";
////        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      }
////    }
//  }
//  if (tableView == self.behaviorTableView) {
//    if (indexPath.section) {
//      cell = [tableView dequeueReusableCellWithIdentifier:@"NewBehaviorCell"];
//      return cell;
//    }
//    cell = [tableView dequeueReusableCellWithIdentifier:@"BehaviorCell" forIndexPath:indexPath];
//    UILabel *textLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
////    if (indexPath.section < [[self gcp] getInitiationTypeAtIndex:indexPath.row].initiations.count) {
////      NSInteger num = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].initiations.count;
//      CAGInitiation *behavior = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:indexPath.row];
////      if (indexPath.row < num) {
//        textLabel.text = behavior.name;
//        textLabel.textColor = behavior.color;
////        cell.accessoryType = UITableViewCellAccessoryNone;
////      }
//    
//    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
//    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
//    if (self.currentBehavior == indexPath.row) {
//      editButton.hidden = NO;
//      deleteButton.hidden = NO;
//      cell.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
////      todo !!!!! fill in behavior image stuff
//      self.behaviorImageName.text = [NSString stringWithFormat:@"%@ Image", behavior.name];
//      [self.behaviorImageSizeControl setSelectedSegmentIndex:behavior.imageSize];
//    }
//    else {
//      editButton.hidden = YES;
//      deleteButton.hidden = YES;
//      cell.backgroundColor = [UIColor whiteColor];
//    }
////      else if (indexPath.row == num) {
////        textLabel.text = [NSString stringWithFormat:@"Add %@ Behavior", [self n:initiationType.name]];
////        textLabel.textColor = [UIColor blackColor];
////        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      }
////      else if (indexPath.row == num + 1) {
////        textLabel.text = [NSString stringWithFormat:@"Change %@ Color", initiationType.name];
////        textLabel.textColor = initiationType.color;
////        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      }
////      else if (indexPath.row == num + 2) {
////        textLabel.text = [NSString stringWithFormat:@"Delete All %@ Behaviors", initiationType.name];
////        textLabel.textColor = [UIColor blackColor];
////        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      }
////    }
////    else if (indexPath.section == [self gcp].initiationTypes.count) {
////      textLabel.text = @"Add a Behavior Type";
////      textLabel.textColor = [UIColor blackColor];
////      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////    }
////    else {
////      textLabel.text = @"Delete This Participant";
////      textLabel.textColor = [UIColor blackColor];
////      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////    }
//  }
//  if (tableView == self.responseTableView) {
//    if (indexPath.section) {
//      cell = [tableView dequeueReusableCellWithIdentifier:@"NewResponseCell"];
//      return cell;
//    }
//    cell = [tableView dequeueReusableCellWithIdentifier:@"ResponseCell" forIndexPath:indexPath];
//    UILabel *textLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
////    if (indexPath.section == 0) {
//      NSArray *responses = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses;
//      if (indexPath.row < responses.count) {
//        textLabel.text = ((CAGResponse *)[responses objectAtIndex:indexPath.row]).name;
//        cell.accessoryType = UITableViewCellAccessoryNone;
//      }
//    
//    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
//    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
//    if (self.currentResponse == indexPath.row) {
//      editButton.hidden = NO;
//      deleteButton.hidden = NO;
//      cell.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
//    }
//    else {
//      editButton.hidden = YES;
//      deleteButton.hidden = YES;
//      cell.backgroundColor = [UIColor whiteColor];
//    }
////      else {
////        textLabel.text = @"Add a Suggested Response";
////        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      }
////    }
////    else if (indexPath.section == 1) {
////      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
////      switch (indexPath.row) {
////        case 0:
////          textLabel.text = @"Rewrite Behavior";
////          break;
////          
////        case 1:
////          textLabel.text = @"Choose a Color";
////          break;
////          
////        case 2:
////          textLabel.text = @"Choose an Image";
////          break;
////          
////        case 3:
////          textLabel.text = @"Delete Behavior";
////          break;
////      }
////    }
//  }
//  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.behaviorTypeTableView) {
    if (indexPath.section) {
      // this is a new behavior type cell, no customization needed
      return;
    }
    UILabel *textLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
    if (indexPath.row < [self gcp].initiationTypes.count) {
      textLabel.text = [[self gcp] getInitiationTypeAtIndex:indexPath.row].name;
    }
    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
    UIButton *colorButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_COLOR_TAG];
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
    if (self.currentBehaviorType == indexPath.row) {
      editButton.hidden = NO;
      colorButton.hidden = NO;
      deleteButton.hidden = NO;
      cell.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
    }
    else {
      editButton.hidden = YES;
      colorButton.hidden = YES;
      deleteButton.hidden = YES;
      cell.backgroundColor = [UIColor whiteColor];
    }
  }
  if (tableView == self.behaviorTableView) {
    if (indexPath.section) {
      // new behavior cell, no customization needed
      return;
    }
    UILabel *textLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
    CAGInitiation *behavior = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:indexPath.row];
    textLabel.text = behavior.name;
    textLabel.textColor = behavior.color;
    
    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
    if (self.currentBehavior == indexPath.row) {
      editButton.hidden = NO;
      deleteButton.hidden = NO;
      cell.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
      // todo !!!!! fill in behavior image stuff
      self.behaviorImageName.text = [NSString stringWithFormat:@"%@ Image", behavior.name];
      [self.behaviorImageSizeControl setSelectedSegmentIndex:behavior.imageSize];
    }
    else {
      editButton.hidden = YES;
      deleteButton.hidden = YES;
      cell.backgroundColor = [UIColor whiteColor];
    }
  }
  if (tableView == self.responseTableView) {
    if (indexPath.section) {
      // new response cell, no customization needed
      return;
    }
    UILabel *textLabel = (UILabel *)[cell viewWithTag:TABLE_VIEW_CELL_LABEL_TAG];
    NSArray *responses = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses;
    if (indexPath.row < responses.count) {
      textLabel.text = ((CAGResponse *)[responses objectAtIndex:indexPath.row]).name;
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
    if (self.currentResponse == indexPath.row) {
      editButton.hidden = NO;
      deleteButton.hidden = NO;
      cell.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
    }
    else {
      editButton.hidden = YES;
      deleteButton.hidden = YES;
      cell.backgroundColor = [UIColor whiteColor];
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (tableView == self.behaviorTypeTableView) {
    [self.behaviorTypeTableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
      self.currentBehaviorType = indexPath.row;
      self.currentBehavior = NO_CURRENT;
      self.currentResponse = NO_CURRENT;
      [self.behaviorTypeTableView reloadData];
      [self.behaviorTableView reloadData];
      [self.responseTableView reloadData];
    }
    else {
      UIAlertView *newInitTypeAlertView = [[UIAlertView alloc] initWithTitle:@"Add a Behavior Type" message:@"What should the type be called?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      newInitTypeAlertView.tag = ALERT_VIEW_NEW_INITIATION_TYPE;
      newInitTypeAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      [newInitTypeAlertView show];
    }
//    if (indexPath.section == 0 && [self indexPath:self.currentParticipant notEqualToIndexPath:indexPath]) {
//      self.currentParticipant = indexPath;
//      self.currentInitiation = nil;
//      [self.initiationsTableView reloadData];
//      [self.responsesTableView reloadData];
//    }
//    if (indexPath.section == 1) {
//      UIAlertView *newParticipantAlertView = [[UIAlertView alloc] initWithTitle:@"New Participant" message:@"What is their name?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
//      newParticipantAlertView.tag = ALERT_VIEW_NEW_PARTICIPANT;
//      newParticipantAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//      [newParticipantAlertView show];
//      [self.participantTableView deselectRowAtIndexPath:indexPath animated:YES];
//    }
//    if (indexPath.section == 1) {
//      if (indexPath.row == 0) {
//        UIAlertView *newPasswordAlertView = [[UIAlertView alloc] initWithTitle:@"Set Password" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Set", nil];
//        newPasswordAlertView.tag = ALERT_VIEW_SET_PASSWORD;
//        newPasswordAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
//      }
//      if (indexPath.row == 1) {
//        
//      }
//    }
  }
  if (tableView == self.behaviorTableView) {
    [self.behaviorTableView deselectRowAtIndexPath:indexPath animated:YES];
//    if (indexPath.section < [self gcp].initiationTypes.count) {
    CAGInitiationType *type = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType];
    if (indexPath.section == 0) {
      self.currentBehavior = indexPath.row;
      self.currentResponse = NO_CURRENT;
      [self.behaviorTableView reloadData];
      [self.responseTableView reloadData];
    }
    else {
      UIAlertView *newInitiationAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Add %@ Behavior", [self n:type.name]] message:@"What should the behavior be called?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      newInitiationAlertView.tag = ALERT_VIEW_NEW_INITIATION;
      newInitiationAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      [newInitiationAlertView show];
    }
//      else if (indexPath.row == num + 1) {
//        self.choosingColor = YES;
//        self.choosingTypeColor = YES;
//        self.currentInitiationType = indexPath;
//        if (!self.colorPicker) {
//          self.colorPicker = [[NEOColorPickerViewController alloc] init];
//        }
//        self.colorPicker.delegate = self;
//        self.colorPicker.selectedColor = [[self gcp] getInitiationTypeAtIndex:indexPath.section].color;
//        self.colorPicker.title = initiationTypeName;
//        UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:self.colorPicker];
//        navVC.modalPresentationStyle = UIModalPresentationFormSheet;
//        [self presentViewController:navVC animated:YES completion:nil];
//      }
//      else if (indexPath.row == num + 2) {
//        self.currentInitiation = indexPath;
//        UIAlertView *newInitiationAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Delete All %@ Behaviors", initiationTypeName] message:@"Are you sure you want to delete this behavior type? This cannot be undone." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
//        newInitiationAlertView.tag = ALERT_VIEW_DELETE_BEHAVIOR_TYPE;
//        [newInitiationAlertView show];
//      }
//    }
//    else if (indexPath.section == [self gcp].initiationTypes.count) {
//      UIAlertView *newInitTypeAlertView = [[UIAlertView alloc] initWithTitle:@"Add a Behavior Type" message:@"What should the type be called?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
//      newInitTypeAlertView.tag = ALERT_VIEW_NEW_INITIATION_TYPE;
//      newInitTypeAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//      [newInitTypeAlertView show];
//    }
//    else {
//      NSString *confirmMessage = [NSString stringWithFormat:@"Are you sure you want to delete %@'s data? This cannot be reversed.", [self gcp].name];
//      UIAlertView *newInitTypeAlertView = [[UIAlertView alloc] initWithTitle:@"Delete a Participant" message:confirmMessage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
//      newInitTypeAlertView.tag = ALERT_VIEW_DELETE_PARTICIPANT;
//      [newInitTypeAlertView show];
//    }
  }
  if (tableView == self.responseTableView) {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
      if (indexPath.row < [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses.count) {
        self.currentResponse = indexPath.row;
        [self.responseTableView reloadData];
//        UIActionSheet *responseActions = [[UIActionSheet alloc] initWithTitle:[[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] getResponseAtIndex:indexPath.row].name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Response" otherButtonTitles:@"Rewrite Response", nil];
//        responseActions.tag = ACTION_SHEET_MODIFY_RESPONSE;
//        [responseActions showInView:self.view];
      }
//      else {
//        UIAlertView *newResponseAlertView = [[UIAlertView alloc] initWithTitle:@"Add a Suggested Response" message:@"What response should be suggested after this behavior?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
//        newResponseAlertView.tag = ALERT_VIEW_NEW_RESPONSE;
//        newResponseAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//        [newResponseAlertView show];
//      }
    }
    else {
      UIAlertView *newResponseAlertView = [[UIAlertView alloc] initWithTitle:@"Add a Suggested Response" message:@"What response should be suggested after this behavior?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      newResponseAlertView.tag = ALERT_VIEW_NEW_RESPONSE;
      newResponseAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      [newResponseAlertView show];
    }
//    else if (indexPath.section == 1) {
//      CAGInitiation *initiation = [[[self gcp] getInitiationTypeAtIndex:self.initiationsTableView.indexPathForSelectedRow.section] getInitiationAtIndex:self.initiationsTableView.indexPathForSelectedRow.row];
//      switch (indexPath.row) {
//        case 0: {
//          UIAlertView *renameInitAlertView = [[UIAlertView alloc] initWithTitle:initiation.name message:@"Rewrite This Behavior" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
//          renameInitAlertView.tag = ALERT_VIEW_RENAME_INITIATION;
//          renameInitAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//          [renameInitAlertView show];
//        }
//          break;
//          
//        case 1: {
//          self.choosingColor = YES;
//          if (!self.colorPicker) {
//            self.colorPicker = [[NEOColorPickerViewController alloc] init];
//          }
//          self.colorPicker.delegate = self;
//          self.colorPicker.selectedColor = initiation.color;
//          self.colorPicker.title = initiation.name;
//          UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:self.colorPicker];
//          navVC.modalPresentationStyle = UIModalPresentationFormSheet;
//          [self presentViewController:navVC animated:YES completion:nil];
//        }
//          break;
//          
//        case 2: {
//          if (([UIImagePickerController isSourceTypeAvailable:
//                UIImagePickerControllerSourceTypePhotoLibrary] == NO)) {
//            [[[UIAlertView alloc] initWithTitle:@"No Photos?" message:@"It looks like I can't access your photos, or you device is not capable of storing any. If you're asked to let this app access your photos please press yes or this feature will not work." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
//            return;
//          }
//
//          if (!self.imagePicker) {
//            UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
//            mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//            mediaUI.mediaTypes =
//            [UIImagePickerController availableMediaTypesForSourceType:
//             UIImagePickerControllerSourceTypePhotoLibrary];
//            mediaUI.allowsEditing = NO;
//            mediaUI.delegate = self;
//            self.imagePicker = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
//          }
//          [self.imagePicker presentPopoverFromRect:self.responsesTableView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//        }
//          break;
//          
//        case 3: {
//          UIAlertView *deleteBehavior = [[UIAlertView alloc] initWithTitle:initiation.name message:@"Delete This Behavior" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
//          deleteBehavior.tag = ALERT_VIEW_DELETE_BEHAVIOR;
//          deleteBehavior.alertViewStyle = UIAlertViewStyleDefault;
//          [deleteBehavior show];
//        }
//          break;
//      }
//    }
  }
}

- (BOOL)indexPath:(NSIndexPath *)path1 notEqualToIndexPath:(NSIndexPath *)path2
{
  return (path1 == nil || path2 == nil) || (path1.section != path2.section || path1.row != path2.row);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (alertView.tag) {
//    case ALERT_VIEW_NEW_PARTICIPANT:
//      if (buttonIndex == 1) {
//        NSString *newName = [alertView textFieldAtIndex:0].text;
//        if (![newName isEqualToString:@""]) {
//          for (CAGParticipant *participant in self.participants) {
//            if ([newName caseInsensitiveCompare:participant.name] == NSOrderedSame) {
//              [[[UIAlertView alloc] initWithTitle:@"Duplicate Participant!" message:[NSString stringWithFormat:@"Hey there, you've already got a participant named %@, please choose a different name.", participant.name] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
//              return;
//            }
//          }
//          [self newParticipant:[alertView textFieldAtIndex:0].text];
//        }
//        else {
//          [[[UIAlertView alloc] initWithTitle:@"No Name?" message:@"Sorry, you need to choose a name for all new participants." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
//        }
//      } else {
//        [self.behaviorTypeTableView selectRowAtIndexPath:self.currentParticipant animated:NO scrollPosition:UITableViewScrollPositionNone];
//      }
//      break;
      
    case ALERT_VIEW_NEW_INITIATION_TYPE:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        NSString *newName = [alertView textFieldAtIndex:0].text;
        for (CAGInitiation *initiation in [self gcp].initiationTypes) {
          if ([newName isEqualToString:initiation.name]) {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"You already have %@ behavior type!", [self n:initiation.name]] message:@"Please choose a different one" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            self.currentBehaviorType = NO_CURRENT;
            self.currentBehavior = NO_CURRENT;
            [self.behaviorTableView reloadData];
            [self.responseTableView reloadData];
            return;
          }
        }
        NSLog(@"name: %@", newName);
        [[self gcp] addInitiationType:[[CAGInitiationType alloc] initWithName:newName]];
      }
      self.currentBehaviorType = NO_CURRENT;
      self.currentBehavior = NO_CURRENT;
      [self.behaviorTypeTableView reloadData];
      [self.behaviorTableView reloadData];
      [self.responseTableView reloadData];
      break;
      
    case ALERT_VIEW_RENAME_BEHAVIOR_TYPE:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].name = [alertView textFieldAtIndex:0].text;
      }
      [self.behaviorTypeTableView reloadData];
      [self.behaviorTableView reloadData];
      break;
      
    case ALERT_VIEW_NEW_INITIATION:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] addInitiation:[[CAGInitiation alloc] initWithName:[alertView textFieldAtIndex:0].text]];
      }
      self.currentBehavior = NO_CURRENT;
      [self.behaviorTableView reloadData];
      [self.responseTableView reloadData];
      break;
      
    case ALERT_VIEW_RENAME_INITIATION:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].name = [alertView textFieldAtIndex:0].text;
        [self.behaviorTableView reloadData];
      }
      [self.responseTableView reloadData];
      break;
      
    case ALERT_VIEW_NEW_RESPONSE:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] addResponse:[[CAGResponse alloc] initWithName:[alertView textFieldAtIndex:0].text]];
      }
      [self.responseTableView reloadData];
      break;
      
    case ALERT_VIEW_MODIFY_RESPONSE:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] getResponseAtIndex:self.currentResponse].name = [alertView textFieldAtIndex:0].text;
      }
      [self.responseTableView reloadData];
      break;
      
    case ALERT_VIEW_DELETE_RESPONSE:
      if (buttonIndex == 1) {
        [[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] removeResponseAtIndex:self.currentResponse];
        self.currentResponse = NO_CURRENT;
        [self.responseTableView reloadData];
      }
      break;
      
    case ALERT_VIEW_DELETE_PARTICIPANT:
      if (buttonIndex == 1) {
        [self.participants removeObjectAtIndex:self.currentParticipant];
        self.currentParticipant = NO_CURRENT;
        self.currentBehaviorType = NO_CURRENT;
        self.currentBehavior = NO_CURRENT;
        self.currentResponse = NO_CURRENT;
        [self.behaviorTypeTableView reloadData];
        [self.behaviorTableView reloadData];
        [self.responseTableView reloadData];
      }
      break;
      
    case ALERT_VIEW_DELETE_BEHAVIOR_TYPE:
      if (buttonIndex == 1) {
        [[self gcp] removeInitiationTypeAtIndex:self.currentBehaviorType];
        self.currentBehaviorType = NO_CURRENT;
        self.currentBehavior = NO_CURRENT;
        self.currentResponse = NO_CURRENT;
        [self.behaviorTypeTableView reloadData];
        [self.behaviorTableView reloadData];
        [self.responseTableView reloadData];
      }
      break;
      
    case ALERT_VIEW_DELETE_BEHAVIOR:
      if (buttonIndex == 1) {
        [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] removeInitiationAtIndex:self.currentBehavior];
        self.currentBehavior = NO_CURRENT;
        self.currentResponse = NO_CURRENT;
        [self.behaviorTableView reloadData];
        [self.responseTableView reloadData];
      }
      break;
  }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (actionSheet.tag) {
//    case ACTION_SHEET_MODIFY_RESPONSE:
//      if (buttonIndex == 0) {
//        [[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] removeResponseAtIndex:self.currentResponse];
//        [self.responseTableView reloadData];
//      }
//      else if (buttonIndex == 1) {
//        UIAlertView *modifyResponse = [[UIAlertView alloc] initWithTitle:[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].name message:@"How should this response be rewritten?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rewrite", nil];
//        modifyResponse.tag = ALERT_VIEW_MODIFY_RESPONSE;
//        modifyResponse.alertViewStyle = UIAlertViewStylePlainTextInput;
//        [modifyResponse show];
//      }
//      else {
//        [self.responseTableView reloadData];
//      }
//      break;
  }
}

- (void)colorPickerViewController:(NEOColorPickerBaseViewController *)controller didSelectColor:(UIColor *)color
{
  if (self.choosingTypeColor) {
    [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].color = color;
    self.choosingTypeColor = NO;
  } else {
    [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].color = color;
  }
  [self.behaviorTableView reloadData];
  [self.responseTableView reloadData];
//  if (!self.choosingTypeColor) {
//    [self.behaviorTableView selectRowAtIndexPath:self.currentBehavior animated:NO scrollPosition:UITableViewScrollPositionNone];
//  }
  [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewControllerDidCancel:(NEOColorPickerBaseViewController *)controller
{
  [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].imageUrl = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
  [self.imagePicker dismissPopoverAnimated:YES];
//  [self.responseTableView deselectRowAtIndexPath:self.responseTableView.indexPathForSelectedRow animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [self.imagePicker dismissPopoverAnimated:YES];
}

- (IBAction)editBehaviorTypeName:(id)sender
{
  CAGInitiationType *currentType = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType];
  UIAlertView *renameTypeAlertView = [[UIAlertView alloc] initWithTitle:currentType.name message:@"Rename This Behavior Type?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
  renameTypeAlertView.tag = ALERT_VIEW_RENAME_BEHAVIOR_TYPE;
  renameTypeAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
  [renameTypeAlertView show];
}

- (IBAction)colorBehaviorType:(id)sender
{
  self.choosingColor = YES;
  self.choosingTypeColor = YES;
  if (!self.colorPicker) {
    self.colorPicker = [[NEOColorPickerViewController alloc] init];
  }
  self.colorPicker.delegate = self;
  CAGInitiationType *behaviorType = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType];
  self.colorPicker.selectedColor = behaviorType.color;
  self.colorPicker.title = behaviorType.name;
  UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:self.colorPicker];
  navVC.modalPresentationStyle = UIModalPresentationFormSheet;
  [self presentViewController:navVC animated:YES completion:nil];
}

- (IBAction)deleteBehaviorType:(id)sender
{
  CAGInitiationType *behaviorType = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType];
  UIAlertView *newInitiationAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Delete All %@ Behaviors?", behaviorType.name] message:@"Are you sure you want to delete this behavior type? This cannot be undone." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
  newInitiationAlertView.tag = ALERT_VIEW_DELETE_BEHAVIOR_TYPE;
  [newInitiationAlertView show];
}

- (IBAction)editBehaviorName:(id)sender
{
  CAGInitiation *currentBehavior = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior];
  UIAlertView *renameInitAlertView = [[UIAlertView alloc] initWithTitle:currentBehavior.name message:@"Rename This Behavior?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
  renameInitAlertView.tag = ALERT_VIEW_RENAME_INITIATION;
  renameInitAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
  [renameInitAlertView show];
}

- (IBAction)deleteBehavior:(id)sender
{
  UIAlertView *deleteBehavior = [[UIAlertView alloc] initWithTitle:@"Delete This Behavior?" message:[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].name delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
  deleteBehavior.tag = ALERT_VIEW_DELETE_BEHAVIOR;
  [deleteBehavior show];
}

- (IBAction)editResponseName:(id)sender
{
  UIAlertView *modifyResponse = [[UIAlertView alloc] initWithTitle:[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].name message:@"How should this response be rewritten?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rewrite", nil];
  modifyResponse.tag = ALERT_VIEW_MODIFY_RESPONSE;
  modifyResponse.alertViewStyle = UIAlertViewStylePlainTextInput;
  [modifyResponse show];
}

- (IBAction)deleteResponse:(id)sender
{
  UIAlertView *deleteResponse = [[UIAlertView alloc] initWithTitle:@"Delete This Response?" message:[[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] getResponseAtIndex:self.currentResponse].name delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
  deleteResponse.tag = ALERT_VIEW_DELETE_RESPONSE;
  [deleteResponse show];
}

- (IBAction)chooseBehaviorImage:(id)sender
{
  NSLog(@"choose behavior image");
}

- (IBAction)deleteBehaviorImage:(id)sender
{
  NSLog(@"delete behavior image");
}

- (IBAction)behaviorImageSizeChanged:(id)sender
{
  UISegmentedControl *control = (UISegmentedControl *) sender;
  NSLog(@"behavior image size changed to: %ld", (long) control.selectedSegmentIndex);
  [[[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior] setImageSize:control.selectedSegmentIndex];
}

- (IBAction)chooseParticipant:(id)sender
{
  NSLog(@"choosing new participant");
//  save off current data, choose new participant
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
  [info setObject:[NSNumber numberWithUnsignedInteger:self.currentParticipant] forKey:@"currentParticipant"];
  [info synchronize];
  NSLog(@"chose: %du", participant);
  self.participants = participants;
  self.currentParticipant = participant;
  self.currentBehaviorType = NO_CURRENT;
  self.currentBehavior = NO_CURRENT;
  self.currentResponse = NO_CURRENT;
  [self.behaviorTypeTableView reloadData];
  [self.behaviorTableView reloadData];
  [self.responseTableView reloadData];
  [self.participantPicker dismissViewControllerAnimated:YES completion:nil];
}

@end
