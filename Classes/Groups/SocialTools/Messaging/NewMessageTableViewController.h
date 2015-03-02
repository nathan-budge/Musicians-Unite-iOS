//
//  NewMessageTableViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;
@class User;

@interface NewMessageTableViewController : UITableViewController

@property (nonatomic) Group *group;
@property (nonatomic) User *user;

@end
