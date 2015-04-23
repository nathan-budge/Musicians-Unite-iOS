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
                                                 name:kGroupRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupMemberRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupMemberNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupTaskNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupTaskRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupTaskCompletedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageThreadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kMessageThreadRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageNotification
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
            User *removedMember = [removedMemberData objectAtIndex:1];
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
    else if ([[notification name] isEqualToString:kNewGroupTaskNotification])
    {
        NSArray *newTaskData = notification.object;
        if ([[newTaskData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities greenToastMessage:kNewTaskSuccessMessage];
        }
    }
    else if ([[notification name] isEqualToString:kGroupTaskRemovedNotification])
    {
        NSArray *removedTaskData = notification.object;
        if ([[removedTaskData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities redToastMessage:kTaskRemovedSuccessMessage];
        }
    }
    else if ([[notification name] isEqualToString:kGroupTaskCompletedNotification])
    {
        NSArray *completedTaskData = notification.object;
        if ([[completedTaskData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities greenToastMessage:kTaskCompletedSuccessMessage];
        }
    }
    else if ([[notification name] isEqualToString:kNewMessageThreadNotification])
    {
        NSArray *newThreadData = notification.object;
        if ([[newThreadData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities greenToastMessage:kNewMessageThreadSuccessMessage];
        }
        
    }
    else if ([[notification name] isEqualToString:kMessageThreadRemovedNotification])
    {
        NSArray *removedThreadData = notification.object;
        if ([[removedThreadData objectAtIndex:0] isEqual:self.group])
        {
            [Utilities redToastMessage:kMessageThreadRemovedSuccessMessage];
        }
        
    }
    else if ([[notification name] isEqualToString:kNewMessageNotification])
    {
        NSArray *newMessageData = notification.object;
        if ([[newMessageData objectAtIndex:2] isEqual:self.group])
        {
            [Utilities greenToastMessage:kNewMessageSuccessMessage];
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
