#import "CAGChooseParticipantViewController.h"
#import "CAGChooseParticipantTableViewCell.h"
#import "CAGCustomTypes.h"

#define ALERT_VIEW_NEW_PARTICIPANT    ((int) 1000)
#define ALERT_VIEW_EDIT_PARTICIPANT   ((int) 1001)
#define ALERT_VIEW_DELETE_PARTICIPANT ((int) 1002)
#define BUTTON_EDIT_PARTICIPANT       ((int) 2000)
#define BUTTON_DELETE_PARTICIPANT     ((int) 2001)
#define NO_CURRENT                    ((int) -1)

@interface CAGChooseParticipantViewController ()

@property IBOutlet UITableView *participantTableView;
@property IBOutlet UIButton *addParticipantButton;
@property IBOutlet UIButton *startButton;
@property NSMutableArray *participants;
@property NSInteger selectedParticipant;
@property UIColor *blueColor;

@end

@implementation CAGChooseParticipantViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.selectedParticipant = NO_CURRENT;
  self.startButton.enabled = NO;
  self.blueColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
  
  NSMutableArray *participants = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"participants"]];
  if (participants) {
    self.participants = participants;
  }
  else {
    self.participants = [[NSMutableArray alloc] init];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return @"Participants";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.participants.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  CAGChooseParticipantTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChooseParticipantCell"];
  if (!cell) {
    [tableView registerNib:[UINib nibWithNibName:@"CAGChooseParticipantTableViewCell" bundle:nil] forCellReuseIdentifier:@"ChooseParticipantCell"];
    cell = [tableView dequeueReusableCellWithIdentifier:@"ChooseParticipantCell"];
  }
  UIButton *editButton = (UIButton *)[cell viewWithTag:BUTTON_EDIT_PARTICIPANT];
  UIButton *deleteButton = (UIButton *)[cell viewWithTag:BUTTON_DELETE_PARTICIPANT];
  if (![cell targetForAction:@selector(editParticipant) withSender:nil]) {
    [editButton addTarget:self action:@selector(editParticipant) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton addTarget:self action:@selector(deleteParticipant) forControlEvents:UIControlEventTouchUpInside];
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  CAGChooseParticipantTableViewCell *theCell = (CAGChooseParticipantTableViewCell *)cell;
  CAGParticipant *participant = [self.participants objectAtIndex:indexPath.row];
  theCell.participantNameLabel.text = participant.name;
  if (indexPath.row == self.selectedParticipant) {
    theCell.backgroundColor = self.blueColor;
  }
  else {
    theCell.backgroundColor = [UIColor whiteColor];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (self.selectedParticipant == indexPath.row) {
    // selected the current row, recolor it blue
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    return;
  }
  NSUInteger oldSelected = self.selectedParticipant;
  self.selectedParticipant = indexPath.row;
  NSArray *rows;
  if (oldSelected == NO_CURRENT) {
    rows = @[indexPath];
  }
  else {
    rows = @[indexPath, [NSIndexPath indexPathForRow:oldSelected inSection:0]];
  }
  self.selectedParticipant = indexPath.row;
  self.startButton.enabled = YES;
  [tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != 1) {
    // alert box canceled
    if (alertView.tag == ALERT_VIEW_NEW_PARTICIPANT) {
      // no participant is highlighted anymore, and no new participant was created so we can't start
      self.startButton.enabled = NO;
    }
    return;
  }
  switch (alertView.tag) {
    case ALERT_VIEW_NEW_PARTICIPANT: {
      NSString *name = [alertView textFieldAtIndex:0].text;
      NSLog(@"new name: %@", name);
      [self.participants addObject:[[CAGParticipant alloc] initWithName:name]];
      self.selectedParticipant = self.participants.count - 1;
      [self.participantTableView reloadData];
      [self.participantTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedParticipant inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
      self.startButton.enabled = YES;
    }
      break;
      
    case ALERT_VIEW_EDIT_PARTICIPANT: {
      NSString *name = [alertView textFieldAtIndex:0].text;
      if (name && ![name isEqualToString:@""]) {
        NSLog(@"new name: %@", name);
        ((CAGParticipant *)[self.participants objectAtIndex:self.selectedParticipant]).name = name;
        [self.participantTableView reloadData];
        [self.participantTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedParticipant inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
      }
    }
      break;
      
    case ALERT_VIEW_DELETE_PARTICIPANT: {
      [self.participants removeObjectAtIndex:self.selectedParticipant];
      [self.participantTableView reloadData];
      self.selectedParticipant = NO_CURRENT;
      self.startButton.enabled = NO;
    }
      break;
      
    default:
      break;
  }
}

// makes a name posessive, correcting for names ending in 's'
- (NSString *)s:(NSString *)name
{
  if ([name characterAtIndex:name.length-1] == 's') {
    return [NSString stringWithFormat:@"%@'", name];
  }
  else {
    return [NSString stringWithFormat:@"%@'s", name];
  }
}

- (void)editParticipant
{
  NSString *name = ((CAGParticipant *)[self.participants objectAtIndex:self.selectedParticipant]).name;
  NSString *title = [NSString stringWithFormat:@"Change %@ name?", [self s:name]];
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"Please choose a new name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change", nil];
  alertView.tag = ALERT_VIEW_EDIT_PARTICIPANT;
  alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alertView show];
}

- (void)deleteParticipant
{
  NSString *name = ((CAGParticipant *)[self.participants objectAtIndex:self.selectedParticipant]).name;
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Delete %@?", name] message:@"CAUTION\nThis will delete all behavior types and sessions with this participant." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"DELETE", nil];
  alertView.tag = ALERT_VIEW_DELETE_PARTICIPANT;
  alertView.alertViewStyle = UIAlertViewStyleDefault;
  [alertView show];
}

- (IBAction)newParticipant:(id)sender
{
  self.selectedParticipant = NO_CURRENT;
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Participant" message:@"What is the participant's name?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
  alertView.tag = ALERT_VIEW_NEW_PARTICIPANT;
  alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alertView textFieldAtIndex:0].placeholder = @"Name";
  [alertView show];
}

- (IBAction)start:(id)sender
{
  [self.delegate chooseParticipantViewController:self newListOfParticipants:self.participants choosenParticipant:self.selectedParticipant];
}

@end
