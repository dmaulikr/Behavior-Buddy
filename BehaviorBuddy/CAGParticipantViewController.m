#import "CAGParticipantViewController.h"
#import "CAGTypeTableViewCell.h"
#import "CAGActionTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface CAGParticipantViewController ()

@property IBOutlet UITableView *typeTableView;
@property IBOutlet UITableView *actionTableView;
@property IBOutlet UIView *selectedLineView;

@property CAGParticipant *participant;
@property NSInteger participantIndex;
@property NSInteger sessionIndex;
@property NSInteger settingIndex;
@property NSInteger selectedInitiationType;
@property NSInteger selectedAction;

@property NSMutableArray *performedActions;
@property NSMutableDictionary *disabledActions;
@property UIView *blackoutView;

@end

@implementation CAGParticipantViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.selectedInitiationType = -1;
    self.selectedLineView.hidden = YES;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.typeTableView registerNib:[UINib nibWithNibName:@"CAGTypeTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"TypeCell"];
  [self.actionTableView registerNib:[UINib nibWithNibName:@"CAGActionTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"ActionCell"];
  
  self.blackoutView = [[UIView alloc] initWithFrame:self.view.frame];
  [self.blackoutView setBackgroundColor:[UIColor blackColor]];
  self.blackoutView.alpha = 0.0;
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
  
  self.disabledActions = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
  self.selectedInitiationType = -1;
  self.selectedLineView.hidden = YES;
  [self.performedActions removeAllObjects];
  [self.typeTableView reloadData];
  [self.actionTableView reloadData];
  self.blackoutView.frame = self.view.frame;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)prepareParticipant:(CAGParticipant *)participant withIndex:(NSInteger)index forSession:(NSInteger)session inSetting:(NSInteger)setting
{
  self.participant = participant;
  self.participantIndex = index;
  self.sessionIndex = session;
  self.settingIndex = setting;
  self.performedActions = [[NSMutableArray alloc] init];
  self.disabledActions = [[NSMutableDictionary alloc] init];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.typeTableView) {
    return self.participant.initiationTypes.count;
  }
  else if (tableView == self.actionTableView && self.selectedInitiationType >= 0) {
    return [self.participant getInitiationTypeAtIndex:self.selectedInitiationType].initiations.count;
  }
  return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.typeTableView) {
    return 100;
  }
  else if (tableView == self.actionTableView) {
    BOOL available = [[[self.participant getSessionAtIndex:self.sessionIndex] getSettingAtIndex:self.settingIndex] getAvailabilityForInitiationAtIndex:indexPath.row initiationType:[self.participant getInitiationTypeAtIndex:self.selectedInitiationType]];
    return available ? [[self.participant getInitiationTypeAtIndex:self.selectedInitiationType] getInitiationAtIndex:indexPath.row].imageUrl ? 500 : 100 : 1;
  }
  return 44;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.typeTableView) {
    CAGTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell" forIndexPath:indexPath];
    CAGInitiationType *type = [self.participant getInitiationTypeAtIndex:indexPath.row];
    [cell setType:type];
      NSLog(@"type: %@", type.name);
    [cell setProgress:[[[self.participant getSessionAtIndex:self.sessionIndex] getSettingAtIndex:self.settingIndex] getCompletionPercentageForInitiationType:type]];
    
    [cell setSelected:indexPath.row == self.selectedInitiationType animated:NO];
    return cell;
  }
  else if (tableView == self.actionTableView) {
    CAGActionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
    [cell setCellColor:[self.participant getInitiationTypeAtIndex:self.selectedInitiationType].color];
    [cell setCellInitiation:[[self.participant getInitiationTypeAtIndex:self.selectedInitiationType] getInitiationAtIndex:indexPath.row]];
    BOOL available = [[[self.participant getSessionAtIndex:self.sessionIndex] getSettingAtIndex:self.settingIndex] getAvailabilityForInitiationAtIndex:indexPath.row initiationType:[self.participant getInitiationTypeAtIndex:self.selectedInitiationType]];
    cell.hidden = !available;
    for (NSIndexPath *performedIndexPath in self.performedActions) {
      if (self.selectedInitiationType == performedIndexPath.section && indexPath.row == performedIndexPath.row) {
        [cell setCellFinished:YES];
        return cell;
      }
    }
    [cell setCellFinished:NO];
    return cell;
  }
  return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.typeTableView) {
    self.selectedLineView.hidden = NO;
    self.selectedInitiationType = indexPath.row;
    self.selectedLineView.backgroundColor = [self.participant getInitiationTypeAtIndex:self.selectedInitiationType].color;
    [self.actionTableView reloadData];
  }
  else if (tableView == self.actionTableView) {
    if (![[self.disabledActions objectForKey:[NSString stringWithFormat:@"%lu,%lu", (long) indexPath.row, (long) self.selectedInitiationType]] boolValue]) {
      self.selectedAction = indexPath.row;
      NSArray *responses = [[self.participant getInitiationTypeAtIndex:self.selectedInitiationType] getInitiationAtIndex:self.selectedAction].responses;
      if (!(responses && responses.count)) {
        [self participantResponsesViewDone:nil];
        return;
      }
      CAGParticipantResponsesView *responsesView = [[[NSBundle mainBundle] loadNibNamed:@"CAGParticipantResponsesView" owner:self options:nil] objectAtIndex:0];
      NSString *actionName = [[self.participant getInitiationTypeAtIndex:self.selectedInitiationType] getInitiationAtIndex:self.selectedAction].name;
      [responsesView showResponses:responses forActionName:actionName withDelegate:self];
      responsesView.layer.cornerRadius = 10;
      CGRect frame = responsesView.frame;
      frame.origin.x = self.view.frame.origin.x + self.view.frame.size.width * 0.1;
      frame.size.width = self.view.frame.size.width * 0.8;
      frame.origin.y = self.view.frame.origin.y + self.view.frame.size.height;
      responsesView.frame = frame;
      [self.view addSubview:self.blackoutView];
      [self.view addSubview:responsesView];
      frame.origin.y = 768/2 - 256;
      [UIView animateWithDuration:0.5 animations:^(void) {
        self.blackoutView.alpha = 0.5;
        responsesView.frame = frame;
      }];
    }
  }
}

- (void)done
{
  [[self.participant getSessionAtIndex:self.sessionIndex] getSettingAtIndex:self.settingIndex].finished = YES;
  NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
  NSData *participantsData = [info objectForKey:@"participants"];
  NSMutableArray *participants = [NSKeyedUnarchiver unarchiveObjectWithData:participantsData];
  [participants replaceObjectAtIndex:self.participantIndex withObject:self.participant];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:participants];
  [info setObject:data forKey:@"participants"];
  [info synchronize];
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)participantResponsesViewDone:(CAGParticipantResponsesView *)view
{
  CAGInitiationType *initiationType = [self.participant getInitiationTypeAtIndex:self.selectedInitiationType];
  CAGInitiation *initiation = [initiationType getInitiationAtIndex:self.selectedAction];
  [[[self.participant getSessionAtIndex:self.sessionIndex] getSettingAtIndex:self.settingIndex] initiationPerformed:initiation initiationType:initiationType];
  [self.performedActions addObject:[NSIndexPath indexPathForRow:self.selectedAction inSection:self.selectedInitiationType]];
  [self.typeTableView reloadData];
  [self.typeTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedInitiationType inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
  [self.actionTableView reloadData];
  [self.disabledActions setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%lu,%lu", (long) self.selectedAction, (long) self.selectedInitiationType]];
  if (view) {
    CGRect frame = view.frame;
    frame.origin.y = self.view.frame.origin.y + self.view.frame.size.height;
    [UIView animateWithDuration:0.5 animations:^(void) {
      view.frame = frame;
      self.blackoutView.alpha = 0.0;
    }completion:^(BOOL finished) {
      if (finished) {
        [view removeFromSuperview];
        [self.blackoutView removeFromSuperview];
      }
    }];
  }
}

@end
