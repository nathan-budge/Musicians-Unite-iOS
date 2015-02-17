//
//  UserSettingsViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "UserSettingsViewController.h"


@interface UserSettingsViewController ()

//Firebase reference
@property (nonatomic) Firebase *currentUserRef;

//User information
@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLastName;
@property (weak, nonatomic) IBOutlet UILabel *labelEmail;

@end


@implementation UserSettingsViewController

#pragma mark - Lazy instatination

-(Firebase *)currentUserRef
{
    if (!_currentUserRef) {
        Firebase *ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
        _currentUserRef = [ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", ref.authData.uid]];
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
}


#pragma mark - Keyboard handling

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
