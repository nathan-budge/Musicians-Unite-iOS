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


@implementation GroupTabBarController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *viewControllers = self.viewControllers;
    
    MessagingTableViewController *messagingTableViewController = [viewControllers objectAtIndex:0];
    messagingTableViewController.group = self.group;
    messagingTableViewController.user = self.user;
    
    GroupDetailViewController *groupDetailViewController = [viewControllers objectAtIndex:2];
    groupDetailViewController.group = self.group;
}

@end
