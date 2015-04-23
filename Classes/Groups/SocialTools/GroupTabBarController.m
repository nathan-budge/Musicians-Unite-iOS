//
//  GroupTabBarController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Group Member"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Thread"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Thread Removed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Task"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Task Removed"
                                               object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kGroupRemovedNotification])
    {
        if ([notification.object isEqual:self.group])
        {
            [self dismissKeyboard];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    else if ([[notification name] isEqualToString:kNewGroupMemberNotification])
    {
        NSArray *newMemberData = notification.object;
        if ([[newMemberData objectAtIndex:0] isEqual:self.group])
        {
            User *newMember = [newMemberData objectAtIndex:1];
            
            NSString *successMessage;
            
            if (newMember.completedRegistration)
            {
                successMessage = [NSString stringWithFormat:@"%@ was added to the group", newMember.firstName];
            }
            else
            {
                successMessage = [NSString stringWithFormat:@"%@ was added to the group", newMember.email];
            }
            
            [Utilities greenToastMessage:successMessage];
        }
    }
    else if ([[notification name] isEqualToString:kGroupMemberRemovedNotification])
    {
        NSArray *removedMemberData = notification.object;
        if ([[removedMemberData objectAtIndex:0] isEqual:self.group])
        {
            User *removedMember = notification.object;
            NSString *errorMessage;
            
            if (removedMember.completedRegistration)
            {
                errorMessage = [NSString stringWithFormat:@"%@ was removed", removedMember.firstName];
            }
            else
            {
                errorMessage = [NSString stringWithFormat:@"%@ was removed", removedMember.email];
            }
            
            [Utilities redToastMessage:errorMessage];
        }
    }
    else if ([[notification name] isEqualToString:@"New Task"])
    {
        NSArray *newTaskData = notification.object;
        if ([[newTaskData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities greenToastMessage:kNewTaskSuccessMessage];
        }
    }
    else if ([[notification name] isEqualToString:@"Task Removed"])
    {
        NSArray *removedTaskData = notification.object;
        if ([[removedTaskData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities redToastMessage:kTaskRemovedSuccessMessage];
        }
    }
}


//*****************************************************************************/
#pragma mark - Keyboard Handling
//*****************************************************************************/

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

@end
