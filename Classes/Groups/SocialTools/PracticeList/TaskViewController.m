//
//  TaskViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "TaskViewController.h"
#import "TasksTableViewController.h"
#import "GroupTabBarController.h"
#import "MusicToolsTabBarController.h"

#import "AppConstant.h"

#import "User.h"
#import "Group.h"
#import "Task.h"


@interface TaskViewController ()

@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldTitle;
@property (weak, nonatomic) IBOutlet UITextField *fieldTempo;
@property (weak, nonatomic) IBOutlet UITextView *fieldNotes;

@property (weak, nonatomic) IBOutlet UIButton *buttonCreateOrSave;
@property (weak, nonatomic) IBOutlet UIButton *buttonDelete;
@property (weak, nonatomic) IBOutlet UIButton *buttonMetronome;

@property (nonatomic) GroupTabBarController *groupTabBarController;

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


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.task) {
        self.fieldTitle.text = self.task.title;
        self.fieldTempo.text = self.task.tempo;
        self.fieldNotes.text = self.task.notes;
        
        [self.buttonCreateOrSave setTitle:@"Save" forState:UIControlStateNormal];
        self.buttonDelete.hidden = NO;
        self.buttonMetronome.hidden = NO;
        
    } else {
        [self.buttonCreateOrSave setTitle:@"Create" forState:UIControlStateNormal];
        self.buttonDelete.hidden = YES;
        self.buttonMetronome.hidden = YES;
        
    }
    
    self.groupTabBarController = [self.navigationController.viewControllers objectAtIndex:(self.navigationController.viewControllers.count - 2)];
    NSLog(@"%@", self.groupTabBarController);
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.group)
    {
        NSLog(@"%@", self.groupTabBarController);
        TasksTableViewController *tasksTableViewController = [self.groupTabBarController.viewControllers objectAtIndex:1];
        tasksTableViewController.inset = YES;
    }
}

//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionCreateOrSave:(id)sender
{
    if (self.task) {
        [self actionSave];
    } else {
        [self actionCreate];
    }
}

- (void)actionCreate
{
    if ([self.fieldTitle.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:@"Title required" maskType:SVProgressHUDMaskTypeBlack];
    }
    else if (![self validTempo])
    {
        [SVProgressHUD showErrorWithStatus:@"Invalid tempo" maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *taskRef = [[self.ref childByAppendingPath:@"tasks"] childByAutoId];
        
        Firebase *ownerRef;
        
        if (self.group) {
            ownerRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/tasks", self.group.groupID]];
        } else {
            ownerRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/tasks", self.ref.authData.uid]];
        }
        
        NSDictionary *newTask = @{
                                  @"title":self.fieldTitle.text,
                                  @"tempo":self.fieldTempo.text,
                                  @"notes":self.fieldNotes.text,
                                  @"completed":@NO,
                                  };
        
        [taskRef setValue:newTask];
        
        [ownerRef updateChildValues:@{taskRef.key:@YES}];
        
        [SVProgressHUD showSuccessWithStatus:@"Task created" maskType:SVProgressHUDMaskTypeBlack];
        
        [self dismissKeyboard];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)actionSave
{
    if ([self.fieldTitle.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:@"Title required" maskType:SVProgressHUDMaskTypeBlack];
        
    }
    else if (![self validTempo])
    {
        [SVProgressHUD showErrorWithStatus:@"Invalid tempo" maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", self.task.taskID]];
        
        NSDictionary *updatedTask = @{
                                  @"title":self.fieldTitle.text,
                                  @"tempo":self.fieldTempo.text,
                                  @"notes":self.fieldNotes.text,
                                  };
        
        [taskRef updateChildValues:updatedTask];
        
        [SVProgressHUD showSuccessWithStatus:@"Task saved" maskType:SVProgressHUDMaskTypeBlack];
        
        [self dismissKeyboard];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)actionMetronome:(id)sender
{
    [self performSegueWithIdentifier:@"viewMetronome" sender:nil];
}

- (IBAction)actionDelete:(id)sender
{
    Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", self.task.taskID]];
    
    Firebase *ownerTaskRef;
    
    if (self.group) {
        ownerTaskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/tasks/%@", self.group.groupID, self.task.taskID]];
    } else {
        ownerTaskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/tasks/%@", self.ref.authData.uid, self.task.taskID]];
    }
    
    [taskRef removeValue];
    [ownerTaskRef removeValue];
    
    [SVProgressHUD showSuccessWithStatus:@"Task deleted" maskType:SVProgressHUDMaskTypeBlack];
    
    [self dismissKeyboard];
    
    [self.navigationController popViewControllerAnimated:YES];
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"viewMetronome"]) {
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
    if (self.fieldTempo.text.length == 0) {
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

@end
