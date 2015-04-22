//
//  UserSettingsTableViewController.m
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

#import "UserSettingsTableViewController.h"

#import "User.h"
#import "Group.h"


@interface UserSettingsTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLastName;
@property (weak, nonatomic) IBOutlet UILabel *labelEmail;
@property (weak, nonatomic) IBOutlet UIButton *buttonProfileImage;

@property (nonatomic) User *user;

@end


@implementation UserSettingsTableViewController

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
    
    self.fieldFirstName.text = self.user.firstName;
    self.fieldLastName.text = self.user.lastName;
    self.labelEmail.text = self.user.email;
    
    UIImage *profileImage = self.user.profileImage;
    [self.buttonProfileImage setImage:profileImage forState:UIControlStateNormal];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
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
        Firebase *userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.user.userID]];
        
        NSString * profileImageString = [Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image];
        
        NSDictionary *updatedValues = @{
                                        @"first_name":self.fieldFirstName.text,
                                        @"last_name":self.fieldLastName.text,
                                        @"profile_image":profileImageString,
                                        };
        
        [userRef updateChildValues:updatedValues];
        
        NSDictionary *options = @{
                                  kCRToastTextKey : @"Saved!",
                                  kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                  kCRToastBackgroundColorKey : [UIColor greenColor],
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                  };
        
        [CRToastManager showNotificationWithOptions:options
                                    completionBlock:^{
                                    }];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"First name is required" maskType:SVProgressHUDMaskTypeBlack];
    }
}

- (IBAction)actionProfileImage:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Remove Photo"
                                                    otherButtonTitles:@"Take Photo", @"Choose From Library", nil];
    
    
    
    [actionSheet showInView:self.view];
}

- (IBAction)actionChangePassword:(id)sender
{
    [self performSegueWithIdentifier:@"changePassword" sender:self];
}

- (IBAction)actionDeleteAccount:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please enter your password" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        [SVProgressHUD showWithStatus:@"Deleteing account..." maskType:SVProgressHUDMaskTypeBlack];
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        [self.ref removeUser:self.user.email password:textField.text withCompletionBlock:^(NSError *error) {
            
            if (error)
            {
                switch(error.code) {
                    case FAuthenticationErrorInvalidPassword:
                        [SVProgressHUD showErrorWithStatus:@"Your password is invalid." maskType:SVProgressHUDMaskTypeBlack];
                        break;
                    default:
                        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
                        break;
                }
                
            }
            else
            {
                for (Group *group in self.user.groups) {
                    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", group.groupID, self.user.userID]] removeValue];
                    [Utilities removeEmptyGroups:group.groupID withRef:self.ref];
                }
            
                NSLog(@"%@", self.user.userID);
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.user.userID]] removeValue];
                
                [self.ref unauth];
                self.sharedData.user = nil;
                [SVProgressHUD dismiss];
                [self performSegueWithIdentifier:@"deleteAccount" sender:nil];
                
                NSDictionary *options = @{
                                          kCRToastTextKey : @"Account Deleted",
                                          kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                          kCRToastBackgroundColorKey : [UIColor redColor],
                                          kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                                          kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                                          kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                          kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                          };
                
                [NSThread sleepForTimeInterval:.5];
                [CRToastManager showNotificationWithOptions:options
                                            completionBlock:^{
                                            }];
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


//*****************************************************************************/
#pragma mark - Profile Image Handling
//*****************************************************************************/

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
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

-(void)selectPhoto
{
    NSLog(@"Select Photo Called");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)removePhoto
{
    [self.buttonProfileImage setImage:[UIImage imageNamed:@"profile_logo"] forState:UIControlStateNormal];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.buttonProfileImage setImage:image forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
