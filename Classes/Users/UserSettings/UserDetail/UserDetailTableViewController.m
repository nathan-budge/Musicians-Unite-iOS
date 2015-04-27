//
//  UserDetailTableViewController.m
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

#import "UserDetailTableViewController.h"

#import "User.h"
#import "Group.h"


@interface UserDetailTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLastName;
@property (weak, nonatomic) IBOutlet UILabel *labelEmail;
@property (weak, nonatomic) IBOutlet UIButton *buttonProfileImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSave;

@end


@implementation UserDetailTableViewController

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
    
    self.fieldFirstName.text = self.sharedData.user.firstName;
    self.fieldLastName.text = self.sharedData.user.lastName;
    self.labelEmail.text = self.sharedData.user.email;
    
    UIImage *profileImage = self.sharedData.user.profileImage;
    [self.buttonProfileImage setImage:profileImage forState:UIControlStateNormal];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    self.buttonSave.enabled = NO;
    
    [self.fieldFirstName addTarget:self
                            action:@selector(textFieldDidChange)
                  forControlEvents:UIControlEventEditingChanged];
    
    [self.fieldLastName addTarget:self
                            action:@selector(textFieldDidChange)
                  forControlEvents:UIControlEventEditingChanged];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionDrawerToggle:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (IBAction)actionSave:(id)sender
{
    [self dismissKeyboard];
    
    if (self.fieldFirstName.text.length > 0)
    {
        Firebase *userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kUsersFirebaseNode, self.sharedData.user.userID]];
        
        NSString * profileImageString = [Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image];
        
        NSDictionary *updatedValues = @{
                                        kUserFirstNameFirebaseField:self.fieldFirstName.text,
                                        kUserLastNameFirebaseField:self.fieldLastName.text,
                                        kProfileImageFirebaseField:profileImageString,
                                        };
        
        [userRef updateChildValues:updatedValues];
        
        [Utilities greenToastMessage:kUserDataSavedSuccessMessage];
        
        self.buttonSave.enabled = NO;
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:kNoFirstNameError maskType:SVProgressHUDMaskTypeBlack];
    }
}

- (IBAction)actionProfileImage:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:kCancelButtonTitle
                                               destructiveButtonTitle:kRemovePhotoButtonTitle
                                                    otherButtonTitles:kTakePhotoButtonTitle, kChooseFromLibraryButtonTitle, nil];
    
    
    
    [actionSheet showInView:self.view];
}

- (IBAction)actionChangePassword:(id)sender
{
    [self performSegueWithIdentifier:kChangePasswordSegueIdentifier sender:self];
}

- (IBAction)actionDeleteAccount:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kDeleteAccountAlertMessage message:nil delegate:self cancelButtonTitle:kCancelButtonTitle otherButtonTitles:kConfirmButtonTitle, nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [SVProgressHUD showWithStatus:kDeletingAccountProgressMessage maskType:SVProgressHUDMaskTypeBlack];
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        [self.ref removeUser:self.sharedData.user.email password:textField.text withCompletionBlock:^(NSError *error) {
            
            if (error)
            {
                switch(error.code) {
                    case FAuthenticationErrorInvalidPassword:
                        [SVProgressHUD showErrorWithStatus:kInvalidPasswordError maskType:SVProgressHUDMaskTypeBlack];
                        break;
                    default:
                        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                        break;
                }
            }
            else
            {
                for (Group *group in self.sharedData.user.groups) {
                    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, group.groupID, kMembersFirebaseNode, self.sharedData.user.userID]] removeValue];
                    [Utilities removeEmptyGroups:group.groupID withRef:self.ref];
                }
            
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kUsersFirebaseNode, self.sharedData.user.userID]] removeValue];
                
                [self.ref unauth];
                self.sharedData.user = nil;
                
                //Set initial Load
                
                [SVProgressHUD dismiss];
                
                [self performSegueWithIdentifier:kDeleteAccountSegueIdentifier sender:nil];
                
                [Utilities redToastMessage:kAccountDeletedSuccessMessage];
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
    [self dismissKeyboard];
    return YES;
}

- (void)textFieldDidChange
{
    if ([self.fieldFirstName.text isEqualToString:self.sharedData.user.firstName] && [self.fieldLastName.text isEqualToString:self.sharedData.user.lastName])
    {
        self.buttonSave.enabled = NO;
    }
    else
    {
        self.buttonSave.enabled = YES;
    }
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
    [self.buttonProfileImage setImage:[UIImage imageNamed:kProfileLogoImage] forState:UIControlStateNormal];
    self.buttonSave.enabled = YES;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.buttonProfileImage setImage:image forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:^{
        self.buttonSave.enabled = YES;
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
