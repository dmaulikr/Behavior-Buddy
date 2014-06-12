//
//  CAGRecordBehaviorView.m
//  PsychologyResearch
//
//  Created by Caleb Gomer on 2/28/14.
//  Copyright (c) 2014 Caleb Gomer. All rights reserved.
//

#import "CAGRecordBehaviorView.h"

@implementation CAGRecordBehaviorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)next:(id)sender
{
  [self.delegate recordBehaviorView:self nextBehavior:nil];
//  pass on next info :P
}

- (IBAction)previous:(id)sender
{
  [self.delegate recordBehaviorViewPreviousBehavior:self];
}

@end
