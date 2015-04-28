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
#import "GroupDetailTableViewController.h"
#import "MessageThreadsTableViewController.h"
#import "TasksTableViewController.h"
#import "RecorderViewController.h"

#import "Group.h"
#import "User.h"
#import "Message.h"


@interface GroupTabBarController ()

@property (nonatomic) SharedData *sharedData;

@end

@implementation GroupTabBarController

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *viewControllers = self.viewControllers;
    
    UINavigationController *navigationController;
    
    navigationController = [viewControllers objectAtIndex:0];
    MessageThreadsTableViewController *messagingTableViewController = [navigationController.viewControllers objectAtIndex:0];
    messagingTableViewController.group = self.group;
    
    navigationController = [viewControllers objectAtIndex:1];
    TasksTableViewController *tasksTableViewController = [navigationController.viewControllers objectAtIndex:0];
    tasksTableViewController.group = self.group;
    
    navigationController = [viewControllers objectAtIndex:2];
    RecorderViewController *recorderViewController = [navigationController.viewControllers objectAtIndex:0];
    recorderViewController.group = self.group;
    
    navigationController = [viewControllers objectAtIndex:3];
    GroupDetailTableViewController *groupDetailTableViewController = [navigationController.viewControllers objectAtIndex:0];
    groupDetailTableViewController.group = self.group;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupRemovedNotification
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
            [self performSegueWithIdentifier:@"unwindToGroups" sender:self];
            
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
