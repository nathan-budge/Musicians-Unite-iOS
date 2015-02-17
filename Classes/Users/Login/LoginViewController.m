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
    
    //Add tap gesture for removing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.fieldEmail becomeFirstResponder];
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
                    [SVProgressHUD showErrorWithStatus:@"Invalid email and/or password"];
                    self.fieldPassword.text = @"";
                    break;
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:@"Invalid email and/or password"];
                    self.fieldPassword.text = @"";
                    break;
                case FAuthenticationErrorUserDoesNotExist:
                    [SVProgressHUD showErrorWithStatus:@"User does not exist"];
                    self.fieldPassword.text = @"";
                    break;
                case FAuthenticationErrorNetworkError:
                    [SVProgressHUD showErrorWithStatus:@"Network Error"];
                    self.fieldPassword.text = @"";
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description];
                    self.fieldPassword.text = @"";
                    break;
            }
            
        } else {
            
            [self performSegueWithIdentifier:@"LoginToGroups" sender:sender];
        }
    }];
    
}


- (IBAction)actionTogglePasswordVisibility:(id)sender{
    
    if ([sender isSelected]) {
        [sender setImage:[UIImage imageNamed:@"eye_inactive"] forState:UIControlStateNormal];
        self.fieldPassword.secureTextEntry = YES;
        [sender setSelected:NO];
    } else {
        [sender setImage:[UIImage imageNamed:@"eye_active"] forState:UIControlStateSelected];
        self.fieldPassword.secureTextEntry = NO;
        [sender setSelected:YES];
    }
}


- (IBAction)actionForgotPassword:(id)sender {
    [self.fieldEmail resignFirstResponder];
    [self.fieldPassword resignFirstResponder];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please enter an email address" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    
}

#pragma mark - Forgot Password Alert View

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        if ([alertView textFieldAtIndex:0]) {
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            if (![textField.text isEqualToString:@""] && ![self validateEmail:textField.text])
            {
                [SVProgressHUD showErrorWithStatus:@"Invalid email"];
            }
            
            else {
                
                [self.ref resetPasswordForUser:textField.text withCompletionBlock:^(NSError *error) {
                    
                    if (error) {
                        NSLog(@"%@", error.description);
                    }
                    
                    else {
                        [SVProgressHUD showSuccessWithStatus:@"Email sent!"];
                        
                    }
                
                }];
            
            }
        }
    }
}


- (BOOL)validateEmail:(NSString *)emailStr {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailStr];
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
