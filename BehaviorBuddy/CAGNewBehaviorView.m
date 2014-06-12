//
//  CAGNewBehaviorView.m
//  PsychologyResearch
//
//  Created by Caleb Gomer on 2/25/14.
//  Copyright (c) 2014 Caleb Gomer. All rights reserved.
//

#import "CAGNewBehaviorView.h"

@implementation CAGNewBehaviorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      _behaviorTypes = [[NSArray alloc] init];
      _selectedBehaviors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)prepareForNewBehaviorWithType:(NSString *)type andBehaviorTypes:(NSArray *)behaviorTypes
{
  _behaviorType = type;
  _title.text = [NSString stringWithFormat:@"New %@ Behavior", type];
  _name.text = @"";
//  _description.text = @"";
  if (behaviorTypes) {
    _behaviorTypes = behaviorTypes;
  }
  else {
    _behaviorTypes = [[NSArray alloc] init];
  }
  for (NSIndexPath *path in _selectedBehaviors) {
    [_nextBehaviors deselectRowAtIndexPath:path animated:NO];
    [_nextBehaviors cellForRowAtIndexPath:path].accessoryType = UITableViewCellAccessoryNone;
  }
  [_selectedBehaviors removeAllObjects];
  [_nextBehaviors reloadData];
  [_nextBehaviors scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _behaviorTypes.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return [[_behaviorTypes objectAtIndex:section] objectForKey:@"name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return ((NSArray *)[[_behaviorTypes objectAtIndex:section] objectForKey:@"behaviors"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"BehaviorCell"];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BehaviorCell" forIndexPath:indexPath];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BehaviorCell"];
  }
  
  cell.textLabel.text = [[[[_behaviorTypes objectAtIndex:indexPath.section] objectForKey:@"behaviors"] objectAtIndex:indexPath.row] objectForKey:@"name"];
  cell.accessoryType = [self getAccessoryTypeWithIndexPath:indexPath];
  return cell;
}

- (int)getAccessoryTypeWithIndexPath:(NSIndexPath *)indexPath
{
  if (!_selectedBehaviors) {
    _selectedBehaviors = [[NSMutableArray alloc] init];
  }
  if ([_selectedBehaviors containsObject:indexPath]) {
    return UITableViewCellAccessoryCheckmark;
  } else {
    return UITableViewCellAccessoryNone;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!_selectedBehaviors) {
    _selectedBehaviors = [[NSMutableArray alloc] init];
  }
  if (![_selectedBehaviors containsObject:indexPath]) {
    [_selectedBehaviors addObject:indexPath];
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
  }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!_selectedBehaviors) {
    _selectedBehaviors = [[NSMutableArray alloc] init];
  }
  if ([_selectedBehaviors containsObject:indexPath]) {
    [_selectedBehaviors removeObject:indexPath];
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
  }
}

- (IBAction)done:(id)sender
{
  if (!_name.text || [_name.text isEqualToString:@""]) {
    [[[UIAlertView alloc] initWithTitle:@"Hold On!" message:@"This new behavior needs a name..." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    return;
  }
  for (NSDictionary *type in _behaviorTypes) {
    if ([[type objectForKey:@"name"] isEqualToString:_behaviorType]) {
      for (NSDictionary *behavior in [type objectForKey:@"behaviors"]) {
        if ([[behavior objectForKey:@"name"] isEqualToString:_name.text]) {
          [[[UIAlertView alloc] initWithTitle:@"Hold On!" message:[NSString stringWithFormat:@"%@ already has a behavior named %@. Please choose a unique name!", _behaviorType, _name.text] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
          return;
        }
      }
    }
  }
  [self.delegate cagNewBehaviorViewDone:self];
}

- (IBAction)cancel:(id)sender
{
  [self.delegate cagNewBehaviorViewCancel:self];
}

@end
