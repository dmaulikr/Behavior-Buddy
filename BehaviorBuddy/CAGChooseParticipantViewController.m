#import "CAGChooseParticipantViewController.h"
#import "CAGChooseParticipantTableViewCell.h"
#import "CAGCustomTypes.h"

#define ALERT_VIEW_NEW_PARTICIPANT    ((int) 1000)
#define ALERT_VIEW_EDIT_PARTICIPANT   ((int) 1001)
#define ALERT_VIEW_DELETE_PARTICIPANT ((int) 1002)
#define BUTTON_EDIT_PARTICIPANT       ((int) 2000)
#define BUTTON_DELETE_PARTICIPANT     ((int) 2001)

@interface CAGChooseParticipantViewController ()

@property IBOutlet UITableView *participantTableView;
@property IBOutlet UIButton *addParticipantButton;
@property IBOutlet UIButton *startButton;
@property NSMutableArray *participants;
@property NSInteger selectedParticipant;

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
  self.selectedParticipant = -1;
  self.startButton.enabled = NO;
  
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  self.selectedParticipant = indexPath.row;
  self.startButton.enabled = YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (alertView.tag) {
    case ALERT_VIEW_NEW_PARTICIPANT: {
      NSString *name = [alertView textFieldAtIndex:0].text;
      NSLog(@"new name: %@", name);
      [self.participants addObject:[[CAGParticipant alloc] initWithName:name]];
      self.selectedParticipant = self.participants.count - 1;
      [self.participantTableView reloadData];
      [self.participantTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedParticipant inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
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
      self.selectedParticipant = -1;
      self.startButton.enabled = NO;
    }
      break;
      
    default:
      break;
  }
}

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
  self.selectedParticipant = -1;
  [self.participantTableView deselectRowAtIndexPath:self.participantTableView.indexPathForSelectedRow animated:YES];
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Participant" message:@"What is the participant's name?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
  alertView.tag = ALERT_VIEW_NEW_PARTICIPANT;
  alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alertView show];
}

- (IBAction)start:(id)sender
{
  [self.delegate chooseParticipantViewController:self newListOfParticipants:self.participants choosenParticipant:self.selectedParticipant];
}

@end
