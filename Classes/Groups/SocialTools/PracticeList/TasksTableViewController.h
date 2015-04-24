//
//  TasksTableViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;

@interface TasksTableViewController : UITableViewController

@property (nonatomic) Group *group;
@property (nonatomic) BOOL inset;

@end
