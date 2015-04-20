//
//  GroupTabBarController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "SVProgressHUD.h"

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
    
    TasksTableViewController *tasksTableViewController = [viewControllers objectAtIndex:1];
    tasksTableViewController.group = self.group;
    
    RecorderViewController *recorderViewController = [viewControllers objectAtIndex:2];
    recorderViewController.group = self.group;
    
    GroupDetailViewController *groupDetailTableViewController = [viewControllers objectAtIndex:3];
    groupDetailTableViewController.group = self.group;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Group Removed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Group Member Removed"
                                               object:nil];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Group Removed"])
    {
        if ([notification.object isEqual:self.group]) {
            [SVProgressHUD showInfoWithStatus:@"Group Removed" maskType:SVProgressHUDMaskTypeBlack];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    else if ([[notification name] isEqualToString:@"Group Member Removed"])
    {
        User *removedMember = notification.object;
        
        if (removedMember.completedRegistration)
        {
            [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@ was removed", removedMember.firstName] maskType:SVProgressHUDMaskTypeBlack];
        }
        else
        {
            [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@ was removed", removedMember.email] maskType:SVProgressHUDMaskTypeBlack];
        }
    }
}

@end
