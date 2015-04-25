//
//  TaskViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "TaskViewController.h"
#import "TasksTableViewController.h"
#import "GroupTabBarController.h"
#import "MusicToolsTabBarController.h"

#import "User.h"
#import "Group.h"
#import "Task.h"


@interface TaskViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (nonatomic) GroupTabBarController *groupTabBarController;

@property (nonatomic) NSString *taskID; //Keep track of new task ID

@property (weak, nonatomic) IBOutlet UITextField *fieldTitle;
@property (weak, nonatomic) IBOutlet UITextField *fieldTempo;
@property (weak, nonatomic) IBOutlet UITextView *fieldNotes;

@property (weak, nonatomic) IBOutlet UIButton *buttonCreateOrDelete;
@property (weak, nonatomic) IBOutlet UIButton *buttonMetronome;

@end


@implementation TaskViewController

//*****************************************************************************/
#pragma mark - Lazy instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if(!_ref){
        _ref =[[Firebase alloc] initWithUrl:FIREBASE_URL];
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
    
    if (self.task)
    {
        self.fieldTitle.text = self.task.title;
        self.fieldTempo.text = self.task.tempo;
        self.fieldNotes.text = self.task.notes;
        
        [self.buttonCreateOrDelete setTitle:kDeleteButtonTitle forState:UIControlStateNormal];
        [self.buttonCreateOrDelete setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(38/255.0) blue:(19/255.0) alpha:1]];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSave)];
        self.buttonMetronome.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        [self.buttonCreateOrDelete setTitle:kCreateButtonTitle forState:UIControlStateNormal];
        [self.buttonCreateOrDelete setBackgroundColor:[UIColor colorWithRed:(95/255.0) green:(200/255.0) blue:(235/255.0) alpha:1]];
        self.buttonMetronome.hidden = YES;
    }
    
    self.groupTabBarController = [self.navigationController.viewControllers objectAtIndex:(self.navigationController.viewControllers.count - 2)];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.task)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserTaskRemovedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kGroupTaskRemovedNotification
                                                   object:nil];
        
        [self.fieldTitle addTarget:self
                                action:@selector(textFieldDidChange)
                      forControlEvents:UIControlEventEditingChanged];
        
        [self.fieldTempo addTarget:self
                            action:@selector(textFieldDidChange)
                  forControlEvents:UIControlEventEditingChanged];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewUserTaskNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewGroupTaskNotification
                                                   object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.group)
    {
        TasksTableViewController *tasksTableViewController = [self.groupTabBarController.viewControllers objectAtIndex:1];
        tasksTableViewController.inset = YES;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissKeyboard];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionCreateOrDelete:(id)sender
{
    self.task ? [self actionDelete] : [self actionCreate];
}

- (void)actionCreate
{
    if ([self.fieldTitle.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:kNoTaskTitleError maskType:SVProgressHUDMaskTypeBlack];
    }
    else if (![self validTempo])
    {
        [SVProgressHUD showErrorWithStatus:kInvalidTempoError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *taskRef = [[self.ref childByAppendingPath:kTasksFirebaseNode] childByAutoId];
        
        self.taskID = taskRef.key;
        
        Firebase *ownerRef;
        
        NSDictionary *newTask;
        if (self.group)
        {
            ownerRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kTasksFirebaseNode]];
            
            newTask = @{
                          kTaskTitleFirebaseField:self.fieldTitle.text,
                          kTaskTempoFirebaseField:self.fieldTempo.text,
                          kTaskNotesFirebaseField:self.fieldNotes.text,
                          kTaskCompletedFirebaseField:@NO,
                          kTaskGroupFirebaseField:self.group.groupID,
                          };
        }
        else
        {
            ownerRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kUsersFirebaseNode, self.sharedData.user.userID, kTasksFirebaseNode]];
            
            newTask = @{
                          kTaskTitleFirebaseField:self.fieldTitle.text,
                          kTaskTempoFirebaseField:self.fieldTempo.text,
                          kTaskNotesFirebaseField:self.fieldNotes.text,
                          kTaskCompletedFirebaseField:@NO,
                          };
        }
        
        [taskRef setValue:newTask];
        [ownerRef updateChildValues:@{taskRef.key:@YES}];
    }
}

- (void)actionDelete
{
    Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kTasksFirebaseNode, self.task.taskID]];
    
    Firebase *ownerTaskRef;
    
    if (self.group)
    {
        ownerTaskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kTasksFirebaseNode, self.task.taskID]];
    }
    else
    {
        ownerTaskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kUsersFirebaseNode, self.sharedData.user.userID, kTasksFirebaseNode, self.task.taskID]];
    }
    
    [taskRef removeValue];
    [ownerTaskRef removeValue];
}

- (void)actionSave
{
    if ([self.fieldTitle.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:kNoTaskTitleError maskType:SVProgressHUDMaskTypeBlack];
        
    }
    else if (![self validTempo])
    {
        [SVProgressHUD showErrorWithStatus:kInvalidTempoError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kTasksFirebaseNode, self.task.taskID]];
        
        NSDictionary *updatedTask = @{
                                      kTaskTitleFirebaseField:self.fieldTitle.text,
                                      kTaskTempoFirebaseField:self.fieldTempo.text,
                                      kTaskNotesFirebaseField:self.fieldNotes.text,
                                      };
        
        [taskRef updateChildValues:updatedTask];
        
        [Utilities greenToastMessage:kTaskSavedSuccessMessage];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (IBAction)actionMetronome:(id)sender
{
    [self performSegueWithIdentifier:kMetronomeSegueIdentifier sender:nil];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewUserTaskNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            Task *newTask = notification.object;
            if ([newTask.taskID isEqualToString:self.taskID])
            {
                self.taskID = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kNewGroupTaskNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            NSArray *newTaskData = notification.object;
            Task *newTask = [newTaskData objectAtIndex:1];
            if ([newTask.taskID isEqualToString:self.taskID])
            {
                self.taskID = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kUserTaskRemovedNotification])
    {
        if ([notification.object isEqual:self.task])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if ([[notification name] isEqualToString:kGroupTaskRemovedNotification])
    {
        NSArray *removedTaskData = notification.object;
        if ([[removedTaskData objectAtIndex:1] isEqual:self.task])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:kMetronomeSegueIdentifier])
    {
        MusicToolsTabBarController *destViewController = segue.destinationViewController;
        destViewController.tempo = [self.fieldTempo.text doubleValue];
    }
}


//*****************************************************************************/
#pragma mark - Check Tempo
//*****************************************************************************/

//Adpated from http://stackoverflow.com/questions/565696/nsstring-is-integer
- (BOOL)validTempo
{
    if (self.fieldTempo.text.length == 0)
    {
        return YES;
    }
    
    NSScanner *tempoScanner = [NSScanner scannerWithString:self.fieldTempo.text];
    return [tempoScanner scanInt:nil] && [tempoScanner isAtEnd];
}


//*****************************************************************************/
#pragma mark - Keyboard Handling
//*****************************************************************************/

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [self dismissKeyboard];
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    if ([self.fieldTitle.text isEqualToString:self.task.title] && [self.fieldTempo.text isEqualToString:self.task.tempo] && [self.fieldNotes.text isEqualToString:self.task.notes])
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)textFieldDidChange
{
    if ([self.fieldTitle.text isEqualToString:self.task.title] && [self.fieldTempo.text isEqualToString:self.task.tempo] && [self.fieldNotes.text isEqualToString:self.task.notes])
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

@end
