//
//  GroupDetailViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"

#import "GroupDetailViewController.h"
#import "MemberManagementViewController.h"

#import "Group.h"


@interface GroupDetailViewController ()

@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldGroupName;
@property (weak, nonatomic) IBOutlet UIButton *buttonConfirm;
@property (weak, nonatomic) IBOutlet UIButton *buttonProfileImage;

@end


@implementation GroupDetailViewController

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


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.group) {
        self.fieldGroupName.text = self.group.name;
        
        [self.buttonProfileImage setImage:self.group.profileImage forState:UIControlStateNormal];
        
        [self.buttonConfirm setTitle:@"Leave Group" forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(38/255.0) blue:(19/255.0) alpha:1]];
        
    } else {
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(95/255.0) green:(200/255.0) blue:(235/255.0) alpha:1]];
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.group) {
        self.tabBarController.title = @"Settings";
        self.tabBarController.navigationItem.rightBarButtonItems = nil;
        self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSaveGroup)];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionProfileImage:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                              delegate:self
                                     cancelButtonTitle:@"Cancel"
                                destructiveButtonTitle:@"Remove Photo"
                                     otherButtonTitles:@"Take Photo", @"Choose From Library", nil];

    [actionSheet showInView:self.view];
}

- (IBAction)actionMemberManagement:(id)sender
{
    
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
    } else {
        [self performSegueWithIdentifier:@"viewMemberManagement" sender:self];
    }
}

- (IBAction)actionCreateOrLeaveGroup:(id)sender
{
    self.group ? [self actionLeaveGroup] : [self actionCreateGroup];
}

-(void)actionLeaveGroup
{
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups/%@", self.ref.authData.uid, self.group.groupID]] removeValue];
    
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", self.group.groupID, self.ref.authData.uid]] removeValue];
    
    [Utilities removeEmptyGroups:self.group.groupID withRef:self.ref];
    
    [self dismissKeyboard];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)actionCreateGroup
{
    [SVProgressHUD showWithStatus:@"Creating your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
        
    } else {
        Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
        Firebase *userRef = [self.ref childByAppendingPath:@"users"];
        
        NSDictionary *newGroup = @{
                                   @"name":self.fieldGroupName.text,
                                   @"profile_image":[Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image],
                                   };
        
        [groupRef setValue:newGroup];
        
        [[[userRef childByAppendingPath:self.ref.authData.uid] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
        [[groupRef childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
        
        [self dismissKeyboard];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(void)actionSaveGroup
{
    [SVProgressHUD showWithStatus:@"Saving your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    Firebase *oldGroup =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.group.groupID]];
    
    NSString * profileImageString = [Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image];
    
    NSDictionary *updatedValues = @{
                                    @"name":self.fieldGroupName.text,
                                    @"profile_image":profileImageString,
                                    };
    
    [oldGroup updateChildValues:updatedValues];
    
    [self dismissKeyboard];
    
    [SVProgressHUD showSuccessWithStatus:@"Group saved" maskType:SVProgressHUDMaskTypeBlack];
}


//*****************************************************************************/
#pragma mark - Keyboard Handling
//*****************************************************************************/

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    
    return YES;
}


//*****************************************************************************/
#pragma mark - Prepare for segue
//*****************************************************************************/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewMemberManagement"]) {
        MemberManagementViewController *destViewController = segue.destinationViewController;
        
        if (self.group) {
            destViewController.group = self.group;
            
        } else {
            NSString * profileImageString = [Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image];
            destViewController.group = [[Group alloc] initWithName:self.fieldGroupName.text andProfileImageString:profileImageString];
        }
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
