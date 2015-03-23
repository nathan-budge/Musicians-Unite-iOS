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


@implementation GroupTabBarController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *viewControllers = self.viewControllers;
    
    MessagingTableViewController *messagingTableViewController = [viewControllers objectAtIndex:0];
    messagingTableViewController.group = self.group;
    messagingTableViewController.user = self.user;
    
    GroupDetailViewController *groupDetailViewController = [viewControllers objectAtIndex:1];
    groupDetailViewController.group = self.group;
    
    //UINavigationController *taskNavigationController = [viewControllers objectAtIndex:2];
    //TasksTableViewController *tasksTableViewController = [taskNavigationController.viewControllers objectAtIndex:0];
    TasksTableViewController *tasksTableViewController = [viewControllers objectAtIndex:2];
    tasksTableViewController.group = self.group;
}

@end
