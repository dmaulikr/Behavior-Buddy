#import "CAGParticipantResponsesView.h"
#import "CAGCustomTypes.h"

@implementation CAGParticipantResponsesView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)ok:(id)sender
{
  [self.delegate participantResponsesViewDone:self];
}

- (void)showResponses:(NSArray *)responses forActionName:(NSString *)actionName withDelegate:(id<CAGParticipantResponsesViewDelegate>)delegate
{
  self.actionName = actionName;
  self.responses = responses;
  self.actionNameLabel.text = [NSString stringWithFormat:@"\"%@\"", actionName];
  self.delegate = delegate;
  
  [self.responsesTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ActionCell"];
  [self.responsesTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.responses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
  NSString *responseString = ((CAGResponse *)[self.responses objectAtIndex:indexPath.row]).name;
  NSMutableAttributedString *attString= [[NSMutableAttributedString alloc] initWithString:responseString];
  
  UIFont *font= [UIFont fontWithName:@"Helvetica" size:30.0f];
  [attString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [responseString length])];
  cell.textLabel.attributedText = attString;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
