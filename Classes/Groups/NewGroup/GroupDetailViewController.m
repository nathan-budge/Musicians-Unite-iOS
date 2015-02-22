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

@property (nonatomic) IBOutlet UITextField *fieldGroupName;

@property (nonatomic) IBOutlet UIButton *buttonConfirm;

@end


@implementation GroupDetailViewController

#pragma mark - Lazy instatination

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}



#pragma mark - View Handling

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.group) {
        self.tabBarController.title = @"Settings";
        self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(actionSaveGroup)];
        
        self.fieldGroupName.text = self.group.name;
        
        [self.buttonConfirm setTitle:@"Leave Group" forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(38/255.0) blue:(19/255.0) alpha:1]];
    } else {
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(95/255.0) green:(200/255.0) blue:(235/255.0) alpha:1]];
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [Utilities dismissKeyboard:self.view];
}



#pragma mark - Buttons

- (IBAction)actionMemberManagement:(id)sender {
    
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
    } else {
        [self performSegueWithIdentifier:@"newGroupToMemberManagement" sender:self];
    }
}


- (IBAction)actionCreateOrLeaveGroup:(id)sender {
    self.group ? [self actionLeaveGroup] : [self actionCreateGroup];
}


-(void)actionCreateGroup
{
    [SVProgressHUD showWithStatus:@"Creating your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
    Firebase *userRef = [self.ref childByAppendingPath:@"users"];
    
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
    }
    else {
        [groupRef setValue:@{@"name":self.fieldGroupName.text}];
        
        [[[userRef childByAppendingPath:self.ref.authData.uid] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
        [[groupRef childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
        
        [SVProgressHUD showSuccessWithStatus:@"Group created" maskType:SVProgressHUDMaskTypeBlack];
        
        [Utilities dismissKeyboard:self.view];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}


-(void)actionLeaveGroup
{
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups/%@", self.ref.authData.uid, self.group.groupID]] removeValue];
    
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", self.group.groupID, self.ref.authData.uid]] removeValue];
    
    [Utilities removeEmptyGroups:self.group.groupID withRef:self.ref];
    
    [Utilities dismissKeyboard:self.view];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


-(void)actionSaveGroup
{
    [SVProgressHUD showWithStatus:@"Saving your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    Firebase *oldGroup =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.group.groupID]];
    [oldGroup updateChildValues:@{@"name":self.fieldGroupName.text}];
    
    [Utilities dismissKeyboard:self.view];
    
    [SVProgressHUD showSuccessWithStatus:@"Group saved" maskType:SVProgressHUDMaskTypeBlack];
}



#pragma mark - Keyboard Handling

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [Utilities dismissKeyboard:self.view];
    
    return YES;
}



#pragma mark - Prepare For Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"newGroupToMemberManagement"]) {
        
        MemberManagementViewController *destViewController = segue.destinationViewController;
        
        if (self.group) {
            destViewController.group = self.group;
        } else {
            destViewController.group = [[Group alloc] initWithName:self.fieldGroupName.text];
        }
    }
}

@end
