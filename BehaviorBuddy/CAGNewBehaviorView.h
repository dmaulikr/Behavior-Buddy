//
//  CAGNewBehaviorView.h
//  PsychologyResearch
//
//  Created by Caleb Gomer on 2/25/14.
//  Copyright (c) 2014 Caleb Gomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CAGNewBehaviorViewDelegate;

@interface CAGNewBehaviorView : UIView <UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UILabel *title;
@property IBOutlet UITextField *name;
//@property IBOutlet UITextField *description;
@property IBOutlet UITableView *nextBehaviors;
@property NSString *behaviorType;
@property NSArray *behaviorTypes;
@property id<CAGNewBehaviorViewDelegate> delegate;
@property NSMutableArray *selectedBehaviors;

- (void)prepareForNewBehaviorWithType:(NSString *)type andBehaviorTypes:(NSArray *)behaviorTypes;

@end

@protocol CAGNewBehaviorViewDelegate <NSObject>

@required

- (void)cagNewBehaviorViewDone:(CAGNewBehaviorView *)view;
- (void)cagNewBehaviorViewCancel:(CAGNewBehaviorView *)view;

@end