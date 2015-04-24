//
//  NavigationDrawerViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "NavigationDrawerViewController.h"

#import "User.h"
#import "Group.h"
#import "Task.h"
#import "Message.h"
#import "Recording.h"


@interface NavigationDrawerViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (nonatomic) BOOL initialLoad;

@property (nonatomic, strong) UINavigationController *transitionsNavigationController;

@property (weak, nonatomic) IBOutlet UIButton *buttonHome;
@property (weak, nonatomic) IBOutlet UIButton *buttonUserSettings;
@property (weak, nonatomic) IBOutlet UIButton *buttonMusicTools;
@property (weak, nonatomic) IBOutlet UIButton *buttonPracticeList;

@end


@implementation NavigationDrawerViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

- (Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.transitionsNavigationController = (UINavigationController *)self.slidingViewController.topViewController;
    
    self.initialLoad = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kInitialLoadCompletedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupMemberNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupMemberRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupTaskNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupTaskCompletedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupRecordingNotification
                                               object:nil];
    
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionHome:(id)sender
{
    [self.transitionsNavigationController popToRootViewControllerAnimated:NO];
    self.slidingViewController.topViewController = self.transitionsNavigationController;
    [self.slidingViewController resetTopViewAnimated:YES];
}

-(IBAction)actionMusicTools:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMusicToolsNavigationController];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionPracticeList:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kPracticeListNavigationController];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionUserSettings:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kUserSettingsNavigationController];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionLogout:(id)sender
{
    [SVProgressHUD showWithStatus:kLoggingOutProgressMessage maskType:SVProgressHUDMaskTypeBlack];
    
    SharedData *sharedData = [SharedData sharedInstance];
    
    for (Firebase *ref in sharedData.childObservers){
        [ref removeAllObservers];
    }
    
    for (id controller in sharedData.notificationCenterObservers) {
        [[NSNotificationCenter defaultCenter] removeObserver:controller];
    }
    
    [self.ref unauth];
    
    sharedData.user = nil;
    self.initialLoad = YES;

    [SVProgressHUD dismiss];
    [self performSegueWithIdentifier:kLogoutSegueIdentifier sender:sender];
    
    [Utilities redToastMessage:kLoggedOutSuccessMessage];    
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kInitialLoadCompletedNotification])
    {
        self.initialLoad = NO;
    }
    else if ([[notification name] isEqualToString:kNewGroupNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            if (!self.initialLoad)
            {
                Group *newGroup = notification.object;
                NSString *message = [NSString stringWithFormat:@"%@ %@", kNewGroupSuccessMessage, newGroup.name];
                
                [Utilities greenToastMessage:message];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kGroupRemovedNotification])
    {
        Group *removedGroup = notification.object;
        NSString *message = [NSString stringWithFormat:@"%@ %@", kGroupRemovedSuccessMessage, removedGroup.name];
        
        [Utilities redToastMessage:message];
    }
    else if ([[notification name] isEqualToString:kNewGroupMemberNotification])
    {
        if (!self.initialLoad)
        {
            dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
                
                
                    NSArray *newMemberData = notification.object;
                    Group *group = [newMemberData objectAtIndex:0];
                    User *newMember = [newMemberData objectAtIndex:1];
                    
                    NSString *message;
                    
                    if (newMember.completedRegistration)
                    {
                        message = [NSString stringWithFormat:@"%@: %@ was added",group.name, newMember.firstName];
                    }
                    else
                    {
                        message = [NSString stringWithFormat:@"%@: %@ was added", group.name, newMember.email];
                    }
                    
                    [Utilities greenToastMessage:message];
                
            });
        }
    }
    else if ([[notification name] isEqualToString:kGroupMemberRemovedNotification])
    {
        NSArray *removedMemberData = notification.object;
        Group *group = [removedMemberData objectAtIndex:0];
        User *removedMember = [removedMemberData objectAtIndex:1];
        
        NSString *message;
        
        if (removedMember.completedRegistration)
        {
            message = [NSString stringWithFormat:@"%@: %@ was removed",group.name, removedMember.firstName];
        }
        else
        {
            message = [NSString stringWithFormat:@"%@: %@ was removed", group.name, removedMember.email];
        }
        
        [Utilities redToastMessage:message];
    }
    else if ([[notification name] isEqualToString:kNewGroupTaskNotification])
    {
        if (!self.initialLoad)
        {
            dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
                
                NSArray *newTaskData = notification.object;
                Group *group = [newTaskData objectAtIndex:0];
                
                NSString *message = [NSString stringWithFormat:@"%@: %@", group.name, kNewTaskSuccessMessage];
                
                [Utilities greenToastMessage:message];
                
            });
        }
    }
    else if ([[notification name] isEqualToString:kGroupTaskCompletedNotification])
    {
        NSArray *completedTaskData = notification.object;
        Group *group = [completedTaskData objectAtIndex:0];
        Task *completedTask = [completedTaskData objectAtIndex:1];
        
        NSString *message = [NSString stringWithFormat:@"%@: %@ was completed", group.name, completedTask.title];
        
        [Utilities greenToastMessage:message];
    }
    else if ([[notification name] isEqualToString:kNewMessageNotification])
    {
        if (!self.initialLoad)
        {
            dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
                
                NSArray *newMessageData = notification.object;
                Message *newMessage = [newMessageData objectAtIndex:1];
                Group *group = [newMessageData objectAtIndex:2];
                
                if (![newMessage.senderID isEqual:self.sharedData.user.userID])
                {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", newMessage.senderID];
                    NSArray *member = [group.members filteredArrayUsingPredicate:predicate];
                    
                    User *sender;
                    if (member.count > 0)
                    {
                        sender = [member objectAtIndex:0];
                    }
                    else
                    {
                        sender = self.sharedData.user;
                    }
                    
                    NSString *message = [NSString stringWithFormat:@"%@: New message from %@", group.name, sender.firstName];
                    
                    [Utilities greenToastMessage:message];
                }
                
            });
        }
        
    }
    else if ([[notification name] isEqualToString:kNewGroupRecordingNotification])
    {
        if (!self.initialLoad)
        {
            dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
                
                NSArray *newRecordingData = notification.object;
                Group *group = [newRecordingData objectAtIndex:0];
                
                NSString *message = [NSString stringWithFormat:@"%@: %@", group.name, kNewRecordingSuccessMessage];
                
                [Utilities greenToastMessage:message];
                
            });
        }
    }
}

@end
