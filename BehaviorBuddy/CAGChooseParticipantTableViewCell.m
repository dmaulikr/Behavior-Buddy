#import "CAGChooseParticipantTableViewCell.h"

@implementation CAGChooseParticipantTableViewCell

- (void)awakeFromNib
{
  // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
  self.editParticipantButton.hidden = !selected;
  self.deleteParticipantButton.hidden = !selected;
  if (selected) {
    self.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
  }
  else {
    self.backgroundColor = [UIColor whiteColor];
  }
}

- (IBAction)editParticipant:(id)sender
{
  
}

- (IBAction)deleteParticipant:(id)sender
{
  
}

@end
