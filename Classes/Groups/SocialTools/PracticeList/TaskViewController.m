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

#import "AppConstant.h"

#import "User.h"
#import "Task.h"


@interface TaskViewController ()

@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldTitle;
@property (weak, nonatomic) IBOutlet UITextField *fieldTempo;
@property (weak, nonatomic) IBOutlet UITextView *fieldNotes;

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
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionCreate:(id)sender
{
    if ([self.fieldTitle.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Title required" maskType:SVProgressHUDMaskTypeBlack];
        
    } else {
        Firebase *taskRef = [[self.ref childByAppendingPath:@"tasks"] childByAutoId];
        Firebase *userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.ref.authData.uid]];
        
        NSDictionary *newTask = @{
                                   @"title":self.fieldTitle.text,
                                   @"tempo":self.fieldTempo.text,
                                   @"notes":self.fieldNotes.text,
                                   };
        
        [taskRef setValue:newTask];
        
        [[userRef childByAppendingPath:@"tasks"]updateChildValues:@{taskRef.key:@YES}];
        
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
