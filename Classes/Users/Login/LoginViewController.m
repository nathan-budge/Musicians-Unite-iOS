//
//  LoginViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"

#import "LoginViewController.h"


@interface LoginViewController ()

@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *fieldPassword;

@end


@implementation LoginViewController

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


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


//*****************************************************************************/
#pragma mark - Status Bar Color
//*****************************************************************************/

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionLogin:(id)sender
{
    [SVProgressHUD showWithStatus:kLoggingInProgressMessage maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    [self.ref authUser:self.fieldEmail.text password:self.fieldPassword.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
        
        if (error)
        {
            switch(error.code) {
                case FAuthenticationErrorInvalidEmail:
                    [SVProgressHUD showErrorWithStatus:kInvalidEmailPasswordError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:kInvalidEmailPasswordError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorUserDoesNotExist:
                    [SVProgressHUD showErrorWithStatus:kUserDoesNotExistError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorNetworkError:
                    [SVProgressHUD showErrorWithStatus:kNetworkError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                    break;
            }
            self.fieldPassword.text = @"";
        }
        else
        {
            [SVProgressHUD dismiss];
            [self performSegueWithIdentifier:kLoginToGroupSegueIdentifier sender:sender];
        }
    }];
}

- (IBAction)actionTogglePasswordVisibility:(id)sender
{
    [Utilities toggleEyeball:sender];
    self.fieldPassword.secureTextEntry = !self.fieldPassword.secureTextEntry;
    
    //Reset the cursor
    NSString *tmpString = self.fieldPassword.text;
    self.fieldPassword.text = @"";
    self.fieldPassword.text = tmpString;
}

- (IBAction)actionForgotPassword:(id)sender
{
    [self dismissKeyboard];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:kForgotPasswordAlertMessage delegate:self cancelButtonTitle:kCancelButtonTitle otherButtonTitles:kConfirmButtonTitle, nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        [self.ref resetPasswordForUser:textField.text withCompletionBlock:^(NSError *error) {
            
            if (error)
            {
                switch (error.code) {
                    case FAuthenticationErrorInvalidEmail:
                        [SVProgressHUD showErrorWithStatus:kInvalidEmailError maskType:SVProgressHUDMaskTypeBlack];
                        break;
                    default:
                        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                        break;
                }
                self.fieldPassword.text = @"";
            }
            else
            {
                [SVProgressHUD showSuccessWithStatus:kResetPasswordSuccessMessage];
            }
            
        }];
    }
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
    if (textField == self.fieldEmail)
    {
        [self.fieldPassword becomeFirstResponder];
    }
    else if (textField == self.fieldPassword)
    {
        [self dismissKeyboard];
    }

    return YES;
}

@end
