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

//Firebase Reference
@property (nonatomic) Firebase *ref;

//Text Fields
@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *fieldPassword;

@end


@implementation LoginViewController

#pragma mark - Lazy instantiation

- (Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}


#pragma mark - View handling

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add tap gesture for dismissing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


#pragma mark - Status bar color

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


#pragma mark - Buttons

- (IBAction)actionLogin:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Logging in..." maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    [self.ref authUser:self.fieldEmail.text password:self.fieldPassword.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
        
        if (error) {
            switch(error.code) {
                case FAuthenticationErrorInvalidEmail:
                    [SVProgressHUD showErrorWithStatus:@"Invalid email and/or password" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:@"Invalid email and/or password" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorUserDoesNotExist:
                    [SVProgressHUD showErrorWithStatus:@"User does not exist" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorNetworkError:
                    [SVProgressHUD showErrorWithStatus:@"Network Error" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                    break;
            }
            self.fieldPassword.text = @"";
        } else {
            [SVProgressHUD dismiss];
            [self performSegueWithIdentifier:@"LoginToGroups" sender:sender];
        }
    }];
}

- (IBAction)actionTogglePasswordVisibility:(id)sender {
    [Utilities toggleEyeball:sender];
    self.fieldPassword.secureTextEntry = !self.fieldPassword.secureTextEntry;
}


- (IBAction)actionForgotPassword:(id)sender {

    [self dismissKeyboard];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please enter an email address" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}


#pragma mark - Forgot Password Alert View

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        UITextField *textField = [alertView textFieldAtIndex:0];
        [self.ref resetPasswordForUser:textField.text withCompletionBlock:^(NSError *error) {
            
            if (error) {
                switch (error.code) {
                    case FAuthenticationErrorInvalidEmail:
                        [SVProgressHUD showErrorWithStatus:@"Email is invalid" maskType:SVProgressHUDMaskTypeBlack];
                        break;
                    default:
                        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                        break;
                }
                
                self.fieldPassword.text = @"";
            }
            
            else {
                [SVProgressHUD showSuccessWithStatus:@"Email sent!"];
            }
        }];
    }
}


#pragma mark - Keyboard handling

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
    if (textField == self.fieldPassword)
    {
        [self dismissKeyboard];
    }
    return YES;
}

@end
