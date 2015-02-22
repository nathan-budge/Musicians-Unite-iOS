//
//  ChangePasswordViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "ChangePasswordViewController.h"

@interface ChangePasswordViewController ()

//Firebase reference
@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldOldPassword;
@property (weak, nonatomic) IBOutlet UITextField *fieldNewPassword;

@end

@implementation ChangePasswordViewController

#pragma mark - Lazy instatination

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add tap gesture for removing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    
}


#pragma mark - Buttons

- (IBAction)actionSave:(id)sender
{
    
    [SVProgressHUD showWithStatus:@"Changing Password..." maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    [self.ref changePasswordForUser:self.ref.authData.providerData[@"email"] fromOld:self.fieldOldPassword.text toNew:self.fieldNewPassword.text withCompletionBlock:^(NSError *error) {
        if (error) {
            switch (error.code) {
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:@"Invalid password" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                    break;
            }
            self.fieldOldPassword.text = @"";
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
}


#pragma mark - Keyboard handling

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.fieldOldPassword)
    {
        [self.fieldNewPassword becomeFirstResponder];
    }
    
    if (textField == self.fieldNewPassword)
    {
        [self dismissKeyboard];
    }
    
    return YES;
}



@end
