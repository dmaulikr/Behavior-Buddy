//
//  CAGRecordBehaviorView.h
//  PsychologyResearch
//
//  Created by Caleb Gomer on 2/28/14.
//  Copyright (c) 2014 Caleb Gomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CAGRecordBehaviorViewDelegate;

@interface CAGRecordBehaviorView : UIView

@property IBOutlet UITableView *nextBehaviorTableView;
@property id<CAGRecordBehaviorViewDelegate> delegate;

@end

@protocol CAGRecordBehaviorViewDelegate <NSObject>

- (void)recordBehaviorView:(CAGRecordBehaviorView *)rbView nextBehavior:(NSIndexPath *)nextBehavior;
- (void)recordBehaviorViewPreviousBehavior:(CAGRecordBehaviorView *)rbView;
- (void)recordBehaviorViewDone:(CAGRecordBehaviorView *)rbView;
- (void)recordBehaviorViewDiscard:(CAGRecordBehaviorView *)rbView;

@end