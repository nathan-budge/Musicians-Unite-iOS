//
//  NewGroupViewController.m
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

@interface GroupDetailViewController ()

//Firebase reference
@property (nonatomic) Firebase *ref;

//Group name field
@property (nonatomic) IBOutlet UITextField *fieldGroupName;

//Create/ Leave Group button
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


#pragma mark - View handling
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.groupID isEqualToString:@""]) {
        
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(95/255.0) green:(200/255.0) blue:(235/255.0) alpha:1]];
        
    } else {
        
        self.tabBarController.title = @"Settings";
        self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveGroup)];
        
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            NSDictionary *group = snapshot.value;
            self.fieldGroupName.text = group[@"name"];
        }];
        
        [self.buttonConfirm setTitle:@"Leave Group" forState:UIControlStateNormal];
        [self.buttonConfirm setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(38/255.0) blue:(19/255.0) alpha:1]];
    }
    
    //Add tap gesture for dismissing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}



-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"newGroupToMemberManagement"]) {
        MemberManagementViewController *destViewController = segue.destinationViewController;
        destViewController.groupName = self.fieldGroupName.text;
        if (self.groupID) {
            destViewController.groupID = self.groupID;
        }
    }
}

- (IBAction)actionMemberManagement:(id)sender {
    
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
    } else {
        [self performSegueWithIdentifier:@"newGroupToMemberManagement" sender:self];
    }
}

- (IBAction)actionCreateOrLeaveGroup:(id)sender {
    
    if ([self.groupID isEqualToString:@""]) {
        [self createGroup];
    } else {
        [self leaveGroup];
    }
}


//Create a group
-(void)createGroup
{
    [SVProgressHUD showWithStatus:@"Creating your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
    Firebase *userRef = [self.ref childByAppendingPath:@"users"];
    
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
    }
    else {
        //Add New Group
        [groupRef setValue:@{@"name":self.fieldGroupName.text}];
        
        //Add group creator to member lists
        [[[userRef childByAppendingPath:self.ref.authData.uid] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
        [[groupRef childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
        
        [SVProgressHUD showSuccessWithStatus:@"Group created" maskType:SVProgressHUDMaskTypeBlack];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

//Leave a Group
-(void)leaveGroup
{
    //Remove group for user's groups
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups/%@", self.ref.authData.uid, self.groupID]] removeValue];
    
    //Remove user from group's members
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", self.groupID, self.ref.authData.uid]] removeValue];
    
    [Utilities removeEmptyGroups:self.groupID withRef:self.ref];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

//Save a group
-(void)saveGroup
{
    Firebase *oldGroup =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.groupID]];
    
    //Update group name
    [oldGroup updateChildValues:@{@"name":self.fieldGroupName.text}];
}


-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

@end
