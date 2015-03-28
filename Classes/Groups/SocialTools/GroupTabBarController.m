//
//  GroupTabBarController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"
#import "MessagingTableViewController.h"
#import "TasksTableViewController.h"
#import "RecorderViewController.h"


@implementation GroupTabBarController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *viewControllers = self.viewControllers;
    
    MessagingTableViewController *messagingTableViewController = [viewControllers objectAtIndex:0];
    messagingTableViewController.group = self.group;
    messagingTableViewController.user = self.user;
    
    GroupDetailViewController *groupDetailTableViewController = [viewControllers objectAtIndex:1];
    groupDetailTableViewController.group = self.group;
    
    TasksTableViewController *tasksTableViewController = [viewControllers objectAtIndex:2];
    tasksTableViewController.group = self.group;
    
    RecorderViewController *recorderViewController = [viewControllers objectAtIndex:3];
    recorderViewController.group = self.group;
}

@end
