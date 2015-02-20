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
#import "NewGroupViewController.h"
#import "MemberManagementViewController.h"

@interface NewGroupViewController ()

//Firebase reference
@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldGroupName;

@end

@implementation NewGroupViewController

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
    }
}

- (IBAction)actionMemberManagement:(id)sender {
    if ([self.fieldGroupName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Group name required" maskType:SVProgressHUDMaskTypeBlack];
    } else {
        [self performSegueWithIdentifier:@"newGroupToMemberManagement" sender:self];
    }
}

- (IBAction)actionCreateGroup:(id)sender {
    
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


-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

@end
