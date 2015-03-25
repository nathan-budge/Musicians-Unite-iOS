//
//  TaskViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "TaskViewController.h"
#import "TasksTableViewController.h"
#import "GroupTabBarController.h"

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
#pragma mark - View lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.task) {
        self.fieldTitle.text = self.task.title;
        self.fieldTempo.text = self.task.tempo;
        self.fieldNotes.text = self.task.notes;
        
        [self.buttonCreateOrSave setTitle:@"Save" forState:UIControlStateNormal];
        
    } else {
        [self.buttonCreateOrSave setTitle:@"Create" forState:UIControlStateNormal];
        
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.group) {
        GroupTabBarController *groupTabBarController = [self.navigationController.viewControllers objectAtIndex:(self.navigationController.viewControllers.count - 1)];
        TasksTableViewController *tasksTableViewController = [groupTabBarController.viewControllers objectAtIndex:2];
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
    if ([self.fieldTitle.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Title required" maskType:SVProgressHUDMaskTypeBlack];
        
    } else {
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
        
        //[self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)actionSave
{
    if ([self.fieldTitle.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Title required" maskType:SVProgressHUDMaskTypeBlack];
        
    } else {
        Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", self.task.taskID]];
        
        NSDictionary *updatedTask = @{
                                  @"title":self.fieldTitle.text,
                                  @"tempo":self.fieldTempo.text,
                                  @"notes":self.fieldNotes.text,
                                  };
        
        [taskRef updateChildValues:updatedTask];
        
        [SVProgressHUD showSuccessWithStatus:@"Task created" maskType:SVProgressHUDMaskTypeBlack];
        
        [self dismissKeyboard];
        
        //[self.navigationController popToRootViewControllerAnimated:YES];
    }
}

//*****************************************************************************/
#pragma mark - Keyboard handling
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
