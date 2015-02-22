//
//  RegisterViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  keyboardWasShown and keyboardWillBeHidden adapted from https://developer.apple.com/library/prerelease/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "RegisterViewController.h"


@interface RegisterViewController ()

//Firebase references
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *usersRef;

//Text fields
@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLastName;
@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *fieldPassword;

//Scroll view
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

//Buttons
- (IBAction)didPressProfileImageButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *profileImageButton;

@end


@implementation RegisterViewController

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
    
    
    //Notifications for keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


#pragma mark - Status Bar Color

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


#pragma mark - Buttons

- (IBAction)didPressProfileImageButton:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Take Photo", @"Choose From Library", nil];
    [actionSheet showInView:self.view];
}

- (IBAction)actionTogglePasswordVisibility:(id)sender {
    [Utilities toggleEyeball:sender];
    self.fieldPassword.secureTextEntry = !self.fieldPassword.secureTextEntry;
}


- (IBAction)actionRegisterUser:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Registering..." maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    if (self.fieldFirstName.text.length > 0) {
        
        self.usersRef = [self.ref childByAppendingPath:@"users"];
        
        [[[self.usersRef queryOrderedByChild:@"email"] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            if (![snapshot.value isEqual:[NSNull null]]) {
                [self createUser:snapshot.value];
            }
            else {
                [self createUser:nil];
            }
            
        } withCancelBlock:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
        }];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"First name is required" maskType:SVProgressHUDMaskTypeBlack];
        self.fieldPassword.text = @"";
    }
}


- (void)createUser: (NSDictionary *)tempUser
{
    [self.ref createUser:self.fieldEmail.text password:self.fieldPassword.text withCompletionBlock:^(NSError *error) {
        
        if(error) {
            switch (error.code) {
                case FAuthenticationErrorEmailTaken:
                    [SVProgressHUD showErrorWithStatus:@"Email is already taken" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorInvalidEmail:
                    [SVProgressHUD showErrorWithStatus:@"Email is invalid" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:@"Password is invalid" maskType:SVProgressHUDMaskTypeBlack];
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                    break;
            }
            
            self.fieldPassword.text = @"";
        }
        else {
            
            [self.ref authUser:self.fieldEmail.text password:self.fieldPassword.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
                
                if (error) {
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                }
                else {
                    
#warning TODO: Upload profile image
                    NSDictionary *newUser = @{
                                              @"first_name":self.fieldFirstName.text,
                                              @"last_name":self.fieldLastName.text,
                                              @"email":authData.providerData[@"email"],
                                              @"completed_registration":@YES,
                                              };
                    
                    Firebase *newUserRef = [self.usersRef childByAppendingPath:authData.uid];
                    [newUserRef setValue:newUser];
                    
                    if (tempUser != nil) {
                        NSString *tempUserID = [tempUser allKeys][0];
                        [self addGroups:tempUserID withAuthData:authData andNewUserRef:newUserRef];
                    }
                    else {
                        [SVProgressHUD dismiss];
                        [self performSegueWithIdentifier:@"RegisterToGroups" sender:nil];
                    }
                }
            }];
        }
    }];
}


- (void)addGroups: (NSString *)tempUserID withAuthData: (FAuthData *)authData andNewUserRef: (Firebase *)newUserRef
{
    [[self.usersRef childByAppendingPath:[NSString stringWithFormat:@"%@/groups", tempUserID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSArray *userGroups = [snapshot.value allKeys];
        
        for (NSString *groupID in userGroups) {
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members", groupID]] updateChildValues:@{authData.uid:@YES}];
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", groupID, tempUserID]] removeValue];
            [[newUserRef childByAppendingPath:@"groups"] updateChildValues:@{groupID:@YES}];
        }
        
        //Remove the temporary user once complete
        [[self.usersRef childByAppendingPath:tempUserID] removeValue];
        
        [SVProgressHUD dismiss];
        [self performSegueWithIdentifier:@"RegisterToGroups" sender:nil];

    } withCancelBlock:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
    }];
}



#pragma mark - Keyboard Handling

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.fieldPassword.frame.origin) ) {
        
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
        self.scrollView.contentInset = contentInsets;
        self.scrollView.scrollIndicatorInsets = contentInsets;

        [self.scrollView scrollRectToVisible:self.fieldPassword.frame animated:YES];
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
    if (textField == self.fieldFirstName)
    {
        [self.fieldLastName becomeFirstResponder];
    }
    
    if (textField == self.fieldLastName) {
        [self.fieldEmail becomeFirstResponder];
    }
    
    if (textField == self.fieldEmail) {
        [self.fieldPassword becomeFirstResponder];
    }
    
    if (textField == self.fieldPassword) {
        [self dismissKeyboard];
    }
    
    return YES;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self takePhoto];
            break;
        case 1:
            [self selectPhoto];
            break;
        default:
            break;
    }
}

//Code for takePhoto and selectPhoto adapted from http://www.appcoda.com/ios-programming-camera-iphone-app/
-(void)takePhoto {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        
        [myAlertView show];
    } else {
        NSLog(@"Take Photo Called");
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}

-(void)selectPhoto {
    NSLog(@"Select Photo Called");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.profileImageButton setImage:image forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end




