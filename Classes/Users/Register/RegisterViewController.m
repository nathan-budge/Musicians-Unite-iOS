//
//  RegisterViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"

#import "RegisterViewController.h"


@interface RegisterViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *usersRef;

@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLastName;
@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *fieldPassword;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)actionProfileImage:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *profileImageButton;

@end


@implementation RegisterViewController

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

- (IBAction)actionProfileImage:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:kCancelButtonTitle
                                               destructiveButtonTitle:kRemovePhotoButtonTitle
                                                    otherButtonTitles:kTakePhotoButtonTitle, kChooseFromLibraryButtonTitle, nil];
    
    [actionSheet showInView:self.view];
}

- (IBAction)actionTogglePasswordVisibility:(id)sender
{
    [Utilities toggleEyeball:sender];
    self.fieldPassword.secureTextEntry = !self.fieldPassword.secureTextEntry;
    
    //Reset the cursor.
    NSString *tmpString = self.fieldPassword.text;
    self.fieldPassword.text = @"";
    self.fieldPassword.text = tmpString;
}

- (IBAction)actionRegisterUser:(id)sender
{
    [SVProgressHUD showWithStatus:kRegisteringProgressMessage maskType:SVProgressHUDMaskTypeBlack];
    [self dismissKeyboard];
    
    if (self.fieldFirstName.text.length > 0)
    {
        self.usersRef = [self.ref childByAppendingPath:kUsersFirebaseNode];
        
        [[[self.usersRef queryOrderedByChild:kUserEmailFirebaseField] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            if (![snapshot.value isEqual:[NSNull null]])
            {
                [self createUser:snapshot.value];
            }
            else
            {
                [self createUser:nil];
            }
            
        } withCancelBlock:^(NSError *error) {
            NSLog(@"ERROR: %@", error.description);
        }];
        
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:kNoFirstNameError maskType:SVProgressHUDMaskTypeBlack];
        self.fieldPassword.text = @"";
    }
}

- (void)createUser: (NSDictionary *)tempUser
{
    [self.ref createUser:self.fieldEmail.text password:self.fieldPassword.text withCompletionBlock:^(NSError *error) {
        
        if(error)
        {
            switch (error.code) {
                case FAuthenticationErrorEmailTaken:
                    [SVProgressHUD showErrorWithStatus:kEmailTakenError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorInvalidEmail:
                    [SVProgressHUD showErrorWithStatus:kInvalidEmailError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                case FAuthenticationErrorInvalidPassword:
                    [SVProgressHUD showErrorWithStatus:kInvalidPasswordError maskType:SVProgressHUDMaskTypeBlack];
                    break;
                default:
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                    break;
            }
            self.fieldPassword.text = @"";
        }
        else
        {
            [self.ref authUser:self.fieldEmail.text password:self.fieldPassword.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
                
                if (error)
                {
                    [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                }
                else
                {
                    Firebase *newUserRef = [self.usersRef childByAppendingPath:authData.uid];
                    
                    NSString * profileImageString = [Utilities encodeImageToBase64:self.profileImageButton.imageView.image];
                    NSDictionary *newUser = @{
                                              kUserFirstNameFirebaseField:self.fieldFirstName.text,
                                              kUserLastNameFirebaseField:self.fieldLastName.text,
                                              kUserEmailFirebaseField:authData.providerData[@"email"],
                                              kUserCompletedRegistrationFirebaseField:@YES,
                                              kProfileImageFirebaseField:profileImageString,
                                              };
                    
                    [newUserRef setValue:newUser];
                    
                    if (tempUser != nil)
                    {
                        NSString *tempUserID = [tempUser allKeys][0];
                        [self addGroups:tempUserID withAuthData:authData andNewUserRef:newUserRef];
                    }
                    else
                    {
                        [SVProgressHUD dismiss];
                        [self performSegueWithIdentifier:kRegisterToGroupSegueIdentifier sender:nil];
                    }
                }
            }];
        }
    }];
}

- (void)addGroups: (NSString *)tempUserID withAuthData: (FAuthData *)authData andNewUserRef: (Firebase *)newUserRef
{
    [[self.usersRef childByAppendingPath:[NSString stringWithFormat:@"%@/%@", tempUserID, kGroupsFirebaseNode]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSArray *userGroups = [snapshot.value allKeys];
        
        for (NSString *groupID in userGroups) {
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kGroupsFirebaseNode, groupID, kMembersFirebaseNode]] updateChildValues:@{authData.uid:@YES}];
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, groupID, kMembersFirebaseNode, tempUserID]] removeValue];
            [[newUserRef childByAppendingPath:kGroupsFirebaseNode] updateChildValues:@{groupID:@YES}];
        }
        
        //Remove the temporary user once complete
        [[self.usersRef childByAppendingPath:tempUserID] removeValue];
        
        [SVProgressHUD dismiss];
        [self performSegueWithIdentifier:kRegisterToGroupSegueIdentifier sender:nil];

    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Keyboard Handling

// keyboardWasShown and keyboardWillBeHidden adapted from https://developer.apple.com/library/prerelease/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
//*****************************************************************************/


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
    else if (textField == self.fieldLastName)
    {
        [self.fieldEmail becomeFirstResponder];
    }
    else if (textField == self.fieldEmail)
    {
        [self.fieldPassword becomeFirstResponder];
    }
    else if (textField == self.fieldPassword)
    {
        [self dismissKeyboard];
    }
    
    return YES;
}


//*****************************************************************************/
#pragma mark - Profile Image Handling
//*****************************************************************************/

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self removePhoto];
            break;
        case 1:
            [self takePhoto];
            break;
        case 2:
            [self selectPhoto];
            break;
        default:
            break;
    }
}

//Code for takePhoto and selectPhoto adapted from http://www.appcoda.com/ios-programming-camera-iphone-app/
-(void)takePhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:kError
                                                              message:kNoCameraError
                                                             delegate:nil
                                                    cancelButtonTitle:kConfirmButtonTitle
                                                    otherButtonTitles: nil];
        
        [myAlertView show];
    }
    else
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}

-(void)selectPhoto
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)removePhoto
{
    [self.profileImageButton setImage:[UIImage imageNamed:kProfileLogoImage] forState:UIControlStateNormal];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.profileImageButton setImage:image forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end