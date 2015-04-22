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
#import "CRToast.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "ChangePasswordTableViewController.h"

#import "User.h"


@interface ChangePasswordTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) User *user;

@property (nonatomic) SharedData *sharedData;

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
    
    self.user = self.sharedData.user;
    
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
            [SVProgressHUD dismiss];
            //[SVProgressHUD showSuccessWithStatus:@"Password Changed!" maskType:SVProgressHUDMaskTypeBlack];
            
            NSDictionary *options = @{
                                      kCRToastTextKey : @"Password Saved!",
                                      kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                      kCRToastBackgroundColorKey : [UIColor greenColor],
                                      kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                                      kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                                      kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                      kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                      };
            
            [NSThread sleepForTimeInterval:.5];
            [CRToastManager showNotificationWithOptions:options
                                        completionBlock:^{
                                        }];
            
            
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
