//
//  TaskViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;
@class Group;
@class Task;

@interface TaskViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic) Group *group;
@property (nonatomic) Task *task;

@end
