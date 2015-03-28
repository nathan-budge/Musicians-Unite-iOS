//
//  ChangePasswordTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/26/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"

#import "ChangePasswordTableViewController.h"
#import "NavigationDrawerViewController.h"

#import "User.h"


@interface ChangePasswordTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) User *user;

@property (weak, nonatomic) IBOutlet UITextField *fieldCurrentPassword;
@property (weak, nonatomic) IBOutlet UITextField *fieldNewPassword;
@end


@implementation ChangePasswordTableViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NavigationDrawerViewController *navigationDrawerViewController = (NavigationDrawerViewController *)self.slidingViewController.underLeftViewController;
    self.user = navigationDrawerViewController.user;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionSave:(id)sender
{
    [SVProgressHUD showWithStatus:@"Changing Password..." maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    [self.ref changePasswordForUser:self.user.email fromOld:self.fieldCurrentPassword.text toNew:self.fieldNewPassword.text withCompletionBlock:^(NSError *error) {
        if (error) {
            switch (error.code) {
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:@"Invalid password" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                    break;
            }
            self.fieldCurrentPassword.text = @"";
            self.fieldNewPassword.text = @"";
        } else {
            [SVProgressHUD showSuccessWithStatus:@"Password Changed!" maskType:SVProgressHUDMaskTypeBlack];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (IBAction)actionTogglePasswordVisibility:(id)sender
{
    [Utilities toggleEyeball:sender];
    self.fieldNewPassword.secureTextEntry = !self.fieldNewPassword.secureTextEntry;
    
    //Reset the cursor.
    NSString *tmpString = self.fieldNewPassword.text;
    self.fieldNewPassword.text = @"";
    self.fieldNewPassword.text = tmpString;
}


//*****************************************************************************/
#pragma mark - Keyboard Handling
//*****************************************************************************/

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.fieldCurrentPassword)
    {
        [self.fieldNewPassword becomeFirstResponder];
    } else if (textField == self.fieldNewPassword)
    {
        [self dismissKeyboard];
        
    }
    
    return YES;
}

@end