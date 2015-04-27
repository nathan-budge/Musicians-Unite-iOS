//
//  TaskTableViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/27/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;
@class Task;

@interface TaskTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic) Group *group;
@property (nonatomic) Task *task;

@end
