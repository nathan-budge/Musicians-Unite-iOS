//
//  UserSettingsViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Navigation drawer methods adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun
//
//  keyboardWasShown and keyboardWillBeHidden adapted from https://developer.apple.com/library/prerelease/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "UserSettingsViewController.h"


@interface UserSettingsViewController ()

//Firebase reference
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *currentUserRef;

//User information
@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLastName;
@property (weak, nonatomic) IBOutlet UILabel *labelEmail;

//Scroll view
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end


@implementation UserSettingsViewController

#pragma mark - Lazy instatination

- (Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}


-(Firebase *)currentUserRef
{
    if (!_currentUserRef) {
        _currentUserRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.ref.authData.uid]];
    }
    
    return _currentUserRef;
}


#pragma mark - View handling

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Pre populate fields with user information
    [self.currentUserRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *values = snapshot.value;
        
        self.fieldFirstName.text = values[@"first_name"];
        self.fieldLastName.text = values[@"last_name"];
        self.labelEmail.text = values[@"email"];
    }];
    
    //Add tap gesture for removing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    //Notifications for keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}


#pragma mark - Unwinding method

- (IBAction)unwindToUserSettings:(UIStoryboardSegue *)segue {
}


#pragma mark - Buttons

- (IBAction)actionDrawerToggle:(id)sender {
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}


- (IBAction)actionSave:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Saving..." maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    if (self.fieldFirstName.text.length > 0) {
        
#warning TODO:Update profile image
        NSDictionary *updatedValues = @{
                                        @"first_name":self.fieldFirstName.text,
                                        @"last_name":self.fieldLastName.text,
                                        };
        
        [self.currentUserRef updateChildValues:updatedValues];
        [SVProgressHUD showSuccessWithStatus:@"Saved" maskType:SVProgressHUDMaskTypeBlack];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"First name is required" maskType:SVProgressHUDMaskTypeBlack];
    }
}


- (IBAction)actionDeleteAccount:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please enter your password" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert show];
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        [SVProgressHUD showWithStatus:@"Deleteing account..." maskType:SVProgressHUDMaskTypeBlack];
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        __block NSString *uid = self.ref.authData.uid;
        
        [self.ref removeUser:self.ref.authData.providerData[@"email"] password:textField.text withCompletionBlock:^(NSError *error) {
            
            if (error) {
                switch(error.code) {
                    case FAuthenticationErrorInvalidPassword:
                        [SVProgressHUD showErrorWithStatus:@"Your password is invalid." maskType:SVProgressHUDMaskTypeBlack];
                        break;
                    default:
                        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                        break;
                }
            } else {
                
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups", uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                    
                    if (![snapshot.value isEqual:[NSNull null]]) {
                        
                        NSDictionary *groups = snapshot.value;
                        for (NSString *groupID in [groups allKeys]) {
                            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", groupID, uid]] removeValue];
                            [Utilities removeEmptyGroups:groupID withRef:self.ref];
                        }
                        
                    }
                } withCancelBlock:^(NSError *error) {
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                }];
                
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", uid]] removeValue];
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"todo/%@", uid]] removeValue];
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", uid]] removeValue];
                
                [self.ref unauth];
                [SVProgressHUD dismiss];
                [self performSegueWithIdentifier:@"DeleteAccount" sender:nil];
            }
        }];
    }
}


#pragma mark - Keyboard handling

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.fieldLastName.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.fieldLastName.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
}

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    return YES;
}

@end
