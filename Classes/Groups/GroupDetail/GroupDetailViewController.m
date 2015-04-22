//
//  GroupDetailViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "GroupDetailViewController.h"
#import "MemberManagementViewController.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"


@interface GroupDetailViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (assign) NSString *groupID; //Keep track of id for new groups

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
    
    if (self.group)
    {
        self.fieldGroupName.text = self.group.name;
        
        [self.buttonProfileImage setImage:self.group.profileImage forState:UIControlStateNormal];
        
        [self.buttonConfirm setTitle:kLeaveGroupButtonTitle forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(38/255.0) blue:(19/255.0) alpha:1]];
        
        [self.fieldGroupName addTarget:self
                                action:@selector(textFieldDidChange)
                      forControlEvents:UIControlEventEditingChanged];
    }
    else
    {
        [self.buttonConfirm setTitle:kCreateButtonTitle forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(95/255.0) green:(200/255.0) blue:(235/255.0) alpha:1]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewGroupNotification
                                                   object:nil];
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    [self.sharedData addNotificationCenterObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.group)
    {
        self.tabBarController.title = kGroupSettingsTitle;
        self.tabBarController.navigationItem.rightBarButtonItems = nil;
        self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSaveGroup)];
        self.tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
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
                                     cancelButtonTitle:kCancelButtonTitle
                                destructiveButtonTitle:kRemovePhotoButtonTitle
                                     otherButtonTitles:kTakePhotoButtonTitle, kChooseFromLibraryButtonTitle, nil];

    [actionSheet showInView:self.view];
}

- (IBAction)actionMemberManagement:(id)sender
{
    
    if ([self.fieldGroupName.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:kGroupNameError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        [self performSegueWithIdentifier:kMemberManagementSegueIdentifier sender:self];
    }
}

- (IBAction)actionCreateOrLeaveGroup:(id)sender
{
    self.group ? [self actionLeaveGroup] : [self actionCreateGroup];
}

-(void)actionLeaveGroup
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:kLeaveGroupAlertMessage
                                                   delegate:self
                                          cancelButtonTitle:kCancelButtonTitle
                                          otherButtonTitles:kConfirmButtonTitle, nil];
    [alert show];
}

-(void)actionCreateGroup
{
    if ([self.fieldGroupName.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:kGroupNameError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *groupRef = [[self.ref childByAppendingPath:kGroupsFirebaseNode] childByAutoId];
        Firebase *userRef = [self.ref childByAppendingPath:kUsersFirebaseNode];
        
        self.groupID = groupRef.key;
        
        NSDictionary *newGroup = @{
                                   kGroupNameFirebaseField:self.fieldGroupName.text,
                                   kProfileImageFirebaseField:[Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image],
                                   };
        
        [groupRef setValue:newGroup];
        
        [[[userRef childByAppendingPath:self.sharedData.user.userID] childByAppendingPath:kGroupsFirebaseNode] updateChildValues:@{groupRef.key:@YES}];
        [[groupRef childByAppendingPath:kMembersFirebaseNode] updateChildValues:@{self.sharedData.user.userID:@YES}];
    }
}

-(void)actionSaveGroup
{
    Firebase *oldGroup =[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kGroupsFirebaseNode, self.group.groupID]];
    
    NSString * profileImageString = [Utilities encodeImageToBase64:self.buttonProfileImage.imageView.image];
    
    NSDictionary *updatedValues = @{
                                    kGroupNameFirebaseField:self.fieldGroupName.text,
                                    kProfileImageFirebaseField:profileImageString,
                                    };
    
    [oldGroup updateChildValues:updatedValues];
    
    [self dismissKeyboard];
    
    NSDictionary *options = @{
                              kCRToastTextKey : kGroupSavedSuccessMessage,
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
    
    self.tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
}


//*****************************************************************************/
#pragma mark - Leave group alert view
//*****************************************************************************/

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kMembersFirebaseNode, self.sharedData.user.userID]] removeValue];
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kUsersFirebaseNode, self.sharedData.user.userID, kGroupsFirebaseNode, self.group.groupID]] removeValue];
        
        //Move this method to attachListenerForRemovedGroups
        [Utilities removeEmptyGroups:self.group.groupID withRef:self.ref];
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewGroupNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            Group *newGroup = notification.object;
            if ([newGroup.groupID isEqualToString:self.groupID])
            {
                [self dismissKeyboard];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            
        });
    }
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

- (void)textFieldDidChange
{
    if (![self.fieldGroupName.text isEqualToString:self.group.name])
    {
        self.tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
    }
}


//*****************************************************************************/
#pragma mark - Prepare for segue
//*****************************************************************************/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kMemberManagementSegueIdentifier])
    {
        MemberManagementViewController *destViewController = segue.destinationViewController;
        
        if (self.group)
        {
            destViewController.group = self.group;
        }
        else
        {
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
    
    if (self.group)
    {
        self.tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.buttonProfileImage setImage:image forState:UIControlStateNormal];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.group)
        {
            self.tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
        }
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
