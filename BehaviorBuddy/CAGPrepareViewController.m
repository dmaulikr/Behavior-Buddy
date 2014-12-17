#import "CAGPrepareViewController.h"
#import "CAGNewBehaviorView.h"
#import <QuartzCore/QuartzCore.h>
#import "CAGCustomTypes.h"
//#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

/***
 Using Color Picker from https://github.com/kartech/colorpicker
 ***/

#define ALERT_VIEW_NEW_INITIATION_TYPE  ((int) 101)
#define ALERT_VIEW_NEW_INITIATION       ((int) 102)
#define ALERT_VIEW_RENAME_INITIATION    ((int) 103)
#define ALERT_VIEW_NEW_RESPONSE         ((int) 104)
#define ALERT_VIEW_DELETE_RESPONSE      ((int) 105)
#define ALERT_VIEW_MODIFY_RESPONSE      ((int) 106)
#define ALERT_VIEW_DELETE_BEHAVIOR_TYPE ((int) 108)
#define ALERT_VIEW_DELETE_BEHAVIOR      ((int) 109)
#define ALERT_VIEW_SET_PASSWORD         ((int) 110)
#define ALERT_VIEW_SET_PASSWORD_CONFIRM ((int) 111)
#define ALERT_VIEW_LOCK_APP             ((int) 112)
#define ALERT_VIEW_UNLOCK_APP           ((int) 118)
#define TABLE_VIEW_CELL_EDIT_TAG        ((int) 113)
#define TABLE_VIEW_CELL_COLOR_TAG       ((int) 114)
#define TABLE_VIEW_CELL_DELETE_TAG      ((int) 115)
#define TABLE_VIEW_CELL_LABEL_TAG       ((int) 116)
#define ALERT_VIEW_RENAME_BEHAVIOR_TYPE ((int) 117)

#define NO_CURRENT NSUIntegerMax

@import Photos;
@import PhotosUI;

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
@property UIImage *behaviorImage;
@property NSString *firstPassword;

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

- (void)viewWillAppear:(BOOL)animated
{
  [self checkAppLock];
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
      self.currentBehaviorType = NO_CURRENT;
      self.currentBehavior = NO_CURRENT;
      self.currentResponse = NO_CURRENT;
      [self.behaviorTypeTableView reloadData];
      [self.behaviorTableView reloadData];
      [self.responseTableView reloadData];
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

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskLandscape;
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
  }
  else if (tableView == self.behaviorTableView) {
    if (section == 0) {
      return @"Behaviors";
    }
  }
  else if (tableView == self.responseTableView) {
    if (section == 0) {
      return @"Responses";
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
    return [self gcp].initiationTypes.count;
  }
  else if (tableView == self.behaviorTableView) {
    if (section) {
      return 1;
    }
    return [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].initiations.count;
  }
  else if (tableView == self.responseTableView) {
    if (section) {
      return 1;
    }
    return [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses.count;
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
      cell.backgroundColor = self.blueColor;
      CAGInitiationType *type = [[self gcp] getInitiationTypeAtIndex:indexPath.row];
      if (type.color == [UIColor blackColor]) {
        colorButton.backgroundColor = [UIColor clearColor];
      }
      else {
        colorButton.backgroundColor = type.color;
      }
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
    
    UIButton *editButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_EDIT_TAG];
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:TABLE_VIEW_CELL_DELETE_TAG];
    if (self.currentBehavior == indexPath.row) {
      editButton.hidden = NO;
      deleteButton.hidden = NO;
      cell.backgroundColor = self.blueColor;
      // todo !!!!! fill in behavior image stuff
//      self.behaviorImageName.text = [NSString stringWithFormat:@"%@ Image", behavior.name];
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
      cell.backgroundColor = self.blueColor;
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
  }
  if (tableView == self.behaviorTableView) {
    [self.behaviorTableView deselectRowAtIndexPath:indexPath animated:YES];
    CAGInitiationType *type = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType];
    if (indexPath.section == 0) {
      self.currentBehavior = indexPath.row;
      self.currentResponse = NO_CURRENT;
      [self.behaviorTableView reloadData];
      [self.responseTableView reloadData];
      CAGInitiation *behavior = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:indexPath.row];
      [self showBehaviorImage:behavior];
    }
    else {
      UIAlertView *newInitiationAlertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Add %@ Behavior", [self n:type.name]] message:@"What should the behavior be called?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      newInitiationAlertView.tag = ALERT_VIEW_NEW_INITIATION;
      newInitiationAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      [newInitiationAlertView show];
    }
  }
  if (tableView == self.responseTableView) {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
      if (indexPath.row < [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses.count) {
        self.currentResponse = indexPath.row;
        [self.responseTableView reloadData];
      }
    }
    else {
      UIAlertView *newResponseAlertView = [[UIAlertView alloc] initWithTitle:@"Add a Suggested Response" message:@"What response should be suggested after this behavior?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
      newResponseAlertView.tag = ALERT_VIEW_NEW_RESPONSE;
      newResponseAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      [newResponseAlertView show];
    }
  }
}

- (BOOL)indexPath:(NSIndexPath *)path1 notEqualToIndexPath:(NSIndexPath *)path2
{
  return (path1 == nil || path2 == nil) || (path1.section != path2.section || path1.row != path2.row);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (alertView.tag) {
    case ALERT_VIEW_NEW_INITIATION_TYPE:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        NSString *newName = [alertView textFieldAtIndex:0].text;
        for (CAGInitiation *initiation in [self gcp].initiationTypes) {
          if ([newName isEqualToString:initiation.name]) {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"You already have %@ behavior type!", [self n:initiation.name]] message:@"Please choose a different one" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            self.currentBehavior = NO_CURRENT;
            [self.behaviorTableView reloadData];
            [self.responseTableView reloadData];
            return;
          }
        }
        NSLog(@"name: %@", newName);
        [[self gcp] addInitiationType:[[CAGInitiationType alloc] initWithName:newName]];
        self.currentBehaviorType = [self gcp].initiationTypes.count-1;
        self.currentBehavior = NO_CURRENT;
        [self.behaviorTypeTableView reloadData];
        [self.behaviorTableView reloadData];
        [self.responseTableView reloadData];
      }
      break;
      
    case ALERT_VIEW_RENAME_BEHAVIOR_TYPE:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].name = [alertView textFieldAtIndex:0].text;
        [self.behaviorTypeTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentBehaviorType inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
      }
      break;
      
    case ALERT_VIEW_NEW_INITIATION:
      if (buttonIndex == 1 && ![[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] addInitiation:[[CAGInitiation alloc] initWithName:[alertView textFieldAtIndex:0].text]];
        self.currentBehavior = [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].initiations.count-1;
        self.currentResponse = NO_CURRENT;
        [self showBehaviorImage:nil];
      }
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
        self.currentResponse = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].responses.count-1;
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
        [self.responseTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentResponse inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        self.currentResponse = NO_CURRENT;
      }
      break;
      
    case ALERT_VIEW_DELETE_BEHAVIOR_TYPE:
      if (buttonIndex == 1) {
        [[self gcp] removeInitiationTypeAtIndex:self.currentBehaviorType];
        [self.behaviorTypeTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentBehaviorType inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        self.currentBehaviorType = NO_CURRENT;
        self.currentBehavior = NO_CURRENT;
        self.currentResponse = NO_CURRENT;
        [self.behaviorTableView reloadData];
        [self.responseTableView reloadData];
      }
      break;
      
    case ALERT_VIEW_DELETE_BEHAVIOR:
      if (buttonIndex == 1) {
        [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] removeInitiationAtIndex:self.currentBehavior];
        [self.behaviorTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentBehavior inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        self.currentBehavior = NO_CURRENT;
        self.currentResponse = NO_CURRENT;
        [self.responseTableView reloadData];
      }
      break;
      
    case ALERT_VIEW_LOCK_APP:
      if (buttonIndex == 1) { // same
        [self lockAppForReal:[[NSUserDefaults standardUserDefaults] stringForKey:@"lockPassword"]];
      } else if (buttonIndex == 2) { // new
        [self requestNewPassword];
      }
      break;
      
    case ALERT_VIEW_SET_PASSWORD:
      self.firstPassword = [alertView textFieldAtIndex:0].text;
      [self confirmNewPassword];
      break;
      
    case ALERT_VIEW_SET_PASSWORD_CONFIRM:
      if ([self.firstPassword isEqualToString:[alertView textFieldAtIndex:0].text]) {
        [self lockAppForReal:self.firstPassword];
      }
      break;
      
    case ALERT_VIEW_UNLOCK_APP:
      [self checkPassword:[alertView textFieldAtIndex:0].text];
      break;
  }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (actionSheet.tag) {
  }
}

- (void)colorPickerViewController:(NEOColorPickerBaseViewController *)controller didSelectColor:(UIColor *)color
{
  if (self.choosingTypeColor) {
    [[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType].color = color;
    self.choosingTypeColor = NO;
    [self.behaviorTypeTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentBehaviorType inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
  } else {
    [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].color = color;
  }
  [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewControllerDidCancel:(NEOColorPickerBaseViewController *)controller
{
  [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  CAGInitiation *behavior = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior];
  behavior.imageUrl = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
  [self.imagePicker dismissPopoverAnimated:YES];
  [self showBehaviorImage:behavior];
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
  if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
    [[[UIAlertView alloc] initWithTitle:@"No Photos?" message:@"It looks like you don't have any photos, or your device is not capable of storing any. If you're asked to let this app access your photos please press yes or this feature will not work." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    return;
  }
  if (!self.imagePicker) {
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    self.imagePicker = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
  }
  CGRect buttonLocation = [self.view convertRect:self.editImageButton.frame fromView:self.editImageButton.superview];
  [self.imagePicker presentPopoverFromRect:buttonLocation inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
}

- (IBAction)deleteBehaviorImage:(id)sender
{
  NSLog(@"delete behavior image");
  CAGInitiation *behavior = [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior];
  behavior.imageUrl = nil;
  behavior.imageSize = 0;
  [self showBehaviorImage:behavior];
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
  self.currentBehaviorType = NO_CURRENT;
  self.currentBehavior = NO_CURRENT;
  self.currentResponse = NO_CURRENT;
  [self.behaviorTypeTableView reloadData];
  [self.behaviorTableView reloadData];
  [self.responseTableView reloadData];
  [self.participantPicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)showBehaviorImage:(CAGInitiation *)behavior
{
  if (!behavior.imageUrl) {
    // no image, show the default
    self.behaviorImageView.image = nil;
    return;
  }
//  code in this section is absolutely awful, thanks to issues with PhotoStream asset URLs and Photos framework in ios 8
//  seriously, Apple, way to screw this up bad:
//  http://stackoverflow.com/questions/26588496/loading-image-from-my-photo-stream-using-uiimagepicker-results-url-and-phasset
//  http://stackoverflow.com/questions/26480526/alassetslibrary-assetforurl-always-returning-nil-for-photos-in-my-photo-stream
  
  NSArray *assets = [[NSArray alloc] initWithObjects:behavior.imageUrl, nil];
  PHImageManager *manager = [PHImageManager defaultManager];
  PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:assets options:nil];
  if (result.count > 0) {
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
//      NSLog(@"stuff: %@, %lu, %@",asset,(unsigned long)idx,stop?@"yes":@"no");
//      NSLog(@"phasset: %@", asset.localIdentifier);
//      NSLog(@"alasset: %@", behavior.imageUrl);
      [manager requestImageForAsset:asset targetSize:CGSizeMake(500, 500) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
//        NSLog(@"image: %@\ninfo: %@",result,info);
        self.behaviorImage = result;
        self.behaviorImageView.image = result;
      }];
    }];
  } else {
    PHFetchResult *stream = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    [stream enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
      PHFetchResult *images = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
      [images enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
//        NSLog(@"stuff: %@, %lu, %@",asset,(unsigned long)idx,stop?@"yes":@"no");
//        NSLog(@"phasset: %@", asset.localIdentifier);
//        NSLog(@"alasset: %@", behavior.imageUrl);
        NSString *assetUrl = [behavior.imageUrl absoluteString];
        NSRange idLocation = [assetUrl rangeOfString:@"?id="];
        NSString *assetId = [assetUrl substringWithRange:NSMakeRange(idLocation.location+idLocation.length, 36)];
        if ([asset.localIdentifier hasPrefix:assetId]) {
//          NSLog(@"yay: found it");
          *stop = YES;
          [manager requestImageForAsset:asset targetSize:CGSizeMake(500, 500) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
//            NSLog(@"image: %@\ninfo: %@",result,info);
            self.behaviorImage = result;
            self.behaviorImageView.image = result;
          }];
        }
      }];
    }];
  }

//  ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
//  
//  ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myAsset)
//  {
//    NSLog(@"url: %@",behavior.imageUrl);
//    NSLog(@"asset: %@",myAsset);
//    if (myAsset) {
//      UIImage *image = [self thumbnailForAsset:myAsset maxPixelSize:500];
//      self.behaviorImage = image;
//      self.behaviorImageView.image = image;
//    } else {
//      [assetslibrary enumerateGroupsWithTypes:ALAssetsGroupPhotoStream usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//         [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
//           if([result.defaultRepresentation.url isEqual:behavior.imageUrl]) {
//             UIImage *image = [self thumbnailForAsset:result maxPixelSize:500];
//             self.behaviorImage = image;
//             self.behaviorImageView.image = image;
//             *stop = YES;
//           }
//         }];
//       } failureBlock:^(NSError *error) {
//         NSLog(@"Error: Cannot load asset from photo stream - %@", [error localizedDescription]);
//         [[[UIAlertView alloc] initWithTitle:@"Sorry..." message:@"The image you selected for this behavior wasn't found. Please edit the image and choose a new one." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
//         self.behaviorImage = nil;
//         self.behaviorImageView.image = nil;
//         [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].imageUrl = nil;
//         [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].imageSize = 0;
//       }];
//    }
//  };
  
//  ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
//  {
//    NSLog(@"Image access error: %@", [myerror localizedDescription]);
//    [[[UIAlertView alloc] initWithTitle:@"Sorry..." message:@"The image you selected for this behavior wasn't found. Please edit the image and choose a new one." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
//    self.behaviorImage = nil;
//    self.behaviorImageView.image = nil;
//    [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].imageUrl = nil;
//    [[[self gcp] getInitiationTypeAtIndex:self.currentBehaviorType] getInitiationAtIndex:self.currentBehavior].imageSize = 0;
//  };
//  
//  [assetslibrary assetForURL:behavior.imageUrl
//                 resultBlock:resultblock
//                failureBlock:failureblock];
}

//// Helper methods for thumbnailForAsset:maxPixelSize:
//static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
//  ALAssetRepresentation *rep = (__bridge id)info;
//  
//  NSError *error = nil;
//  size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
//  
//  if (countRead == 0 && error) {
//    // We have no way of passing this info back to the caller, so we log it, at least.
//    NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
//  }
//  
//  return countRead;
//}
//
//static void releaseAssetCallback(void *info) {
//  // The info here is an ALAssetRepresentation which we CFRetain in thumbnailForAsset:maxPixelSize:.
//  // This release balances that retain.
//  CFRelease(info);
//}
//
//// Returns a UIImage for the given asset, with size length at most the passed size.
//// The resulting UIImage will be already rotated to UIImageOrientationUp, so its CGImageRef
//// can be used directly without additional rotation handling.
//// This is done synchronously, so you should call this method on a background queue/thread.
//- (UIImage *)thumbnailForAsset:(ALAsset *)asset maxPixelSize:(NSUInteger)size
//{
//  NSParameterAssert(asset != nil);
//  NSParameterAssert(size > 0);
//  
//  ALAssetRepresentation *rep = [asset defaultRepresentation];
//  
//  CGDataProviderDirectCallbacks callbacks = {
//    .version = 0,
//    .getBytePointer = NULL,
//    .releaseBytePointer = NULL,
//    .getBytesAtPosition = getAssetBytesCallback,
//    .releaseInfo = releaseAssetCallback,
//  };
//  
//  CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
//  CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
//  
//  CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
//    (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
//    (NSString *)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithUnsignedInteger:size],
//    (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
//  });
//  CFRelease(source);
//  CFRelease(provider);
//  
//  if (!imageRef) {
//    return nil;
//  }
//  
//  UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
//  
//  CFRelease(imageRef);
//  
//  return toReturn;
//}

- (IBAction)lockApp:(id)sender
{
  NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"lockPassword"];
  if (password) {
    [self confirmExistingPassword];
  } else {
    [self requestNewPassword];
  }
}

- (void)checkAppLock
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"locked"]) {
    [self lockScreen:YES];
  }
}

- (void)confirmExistingPassword {
  UIAlertView *confirmpasswordAlert = [[UIAlertView alloc] initWithTitle:@"Lock Behavior Buddy" message:@"Would you like to use the same password as last time, or create a new one?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Same", @"New", nil];
  confirmpasswordAlert.tag = ALERT_VIEW_LOCK_APP;
  [confirmpasswordAlert show];
}

- (void)requestNewPassword
{
  UIAlertView *passwordRequestAlert = [[UIAlertView alloc] initWithTitle:@"Lock Behavior Buddy" message:@"Please choose a password to lock the app." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
  passwordRequestAlert.tag = ALERT_VIEW_SET_PASSWORD;
  passwordRequestAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
  [passwordRequestAlert show];
}

- (void)confirmNewPassword {
  UIAlertView *passwordRequestAlert = [[UIAlertView alloc] initWithTitle:@"Lock Behavior Buddy" message:@"Please confirm your password." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
  passwordRequestAlert.tag = ALERT_VIEW_SET_PASSWORD_CONFIRM;
    passwordRequestAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
  [passwordRequestAlert show];
}

- (void)lockAppForReal:(NSString *)password
{
  NSLog(@"locked!");
  [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"lockPassword"];
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"locked"];
  [self lockScreen:NO];
}

- (void)lockScreen:(BOOL)fast
{
  NSLog(@"screen hidden!");
  if (!self.greyCoverView) {
    self.greyCoverView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.greyCoverView setBackgroundColor:[UIColor blackColor]];
    self.greyCoverView.alpha = 0.0;
  }
  [self.view addSubview:self.greyCoverView];
  [UIView animateWithDuration:fast?0:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void) {
    self.greyCoverView.alpha = 1;
  } completion:^(BOOL finished ) {
    [self showPasswordInput];
  }];
}

- (void)showPasswordInput {[self showPasswordInput:nil];};
- (void)showPasswordInput:(NSString *)title
{
  UIAlertView *passwordInput = [[UIAlertView alloc] initWithTitle:title?title:@"Locked" message:@"Please enter your password to unlock." delegate:self cancelButtonTitle:@"Unlock" otherButtonTitles:nil];
  passwordInput.alertViewStyle = UIAlertViewStyleSecureTextInput;
  passwordInput.tag = ALERT_VIEW_UNLOCK_APP;
  [passwordInput show];
}

- (void)checkPassword:(NSString *)attemptedPassword
{
  NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"lockPassword"];
  if (!password) {
    [self unlockScreen];
    return;
  }
  if (attemptedPassword) {
    if ([attemptedPassword isEqualToString:password]) {
      [self unlockScreen];
      return;
    }
  }
  [self showPasswordInput:@"Wrong Password"];
}

- (void)unlockScreen
{
  [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void) {
    self.greyCoverView.alpha = 0;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"locked"];
  } completion:^(BOOL finished ) {
    [self.greyCoverView removeFromSuperview];
  }];
}

@end
