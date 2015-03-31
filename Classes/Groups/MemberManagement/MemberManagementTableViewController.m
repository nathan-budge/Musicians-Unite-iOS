//
//  MemberManagementTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/29/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "MemberManagementTableViewController.h"

#import "User.h"
#import "Group.h"


@interface MemberManagementTableViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;

@property (nonatomic, weak) SharedData *sharedData;

@property (nonatomic) NSMutableArray *members;

@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UIButton *buttonCreate;

@end


@implementation MemberManagementTableViewController

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

-(Firebase *)userRef
{
    if (!_userRef) {
        _userRef = [self.ref childByAppendingPath:@"users"];
    }
    return _userRef;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}

-(NSMutableArray *)members
{
    if (!_members) {
        _members = [[NSMutableArray alloc] init];
    }
    
    return _members;
}


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.buttonCreate.hidden = YES;
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionAddMember:(id)sender
{
    [SVProgressHUD showWithStatus:@"Adding member..." maskType:SVProgressHUDMaskTypeBlack];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.email=%@", self.fieldEmail.text];
    NSArray *existingMember = [self.members filteredArrayUsingPredicate:predicate];
    
    if (existingMember.count > 0) {
        self.fieldEmail.text = @"";
        [SVProgressHUD showErrorWithStatus:@"Member already exists" maskType:SVProgressHUDMaskTypeBlack];
        
    } else if (![Utilities validateEmail:self.fieldEmail.text]|| [self.fieldEmail.text isEqualToString:self.ref.authData.providerData[@"email"]]){
        self.fieldEmail.text = @"";
        [SVProgressHUD showErrorWithStatus:@"Invalid email" maskType:SVProgressHUDMaskTypeBlack];
        
    } else {
        [self addMemberToList];
        [self dismissKeyboard];
    }
}

-(void)addMemberToList
{
    [[[self.userRef queryOrderedByChild:@"email"] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        User *newMember = [[User alloc] init];
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            newMember.email = self.fieldEmail.text;
            newMember.completedRegistration = NO;
        
        } else {
            NSDictionary *userData = snapshot.value;
            NSString *userID = [userData allKeys][0];
            
            newMember.userID = userID;
            newMember.email = userData[userID][@"email"];
            
            if ([userData[userID][@"completed_registration"] isEqual:@YES]) {
                newMember.completedRegistration = YES;
                newMember.firstName = userData[userID][@"first_name"];
                newMember.lastName = userData[userID][@"last_name"];
                newMember.profileImage = [Utilities decodeBase64ToImage:userData[userID][@"profile_image"]];
                
            }else {
                newMember.completedRegistration = NO;
                newMember.email = self.fieldEmail.text;
            }
            
        }
        
        [self.members addObject:newMember];
        
        self.fieldEmail.text = @"";
        [self.tableView reloadData];
        
        if (self.buttonCreate.hidden) {
            self.buttonCreate.hidden = NO;
        }
        
        [SVProgressHUD showSuccessWithStatus:@"Member Added" maskType:SVProgressHUDMaskTypeBlack];
        
    } withCancelBlock:^(NSError *error) {
        
        NSLog(@"%@", error.description);
        
    }];
}


//*****************************************************************************/
#pragma mark - Keyboard Handling
//*****************************************************************************/

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    
    User *member = [self.members objectAtIndex:indexPath.row];

    UIImageView *profileImageView = (UIImageView *)[cell viewWithTag:1];
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
    profileImageView.layer.masksToBounds = YES;
    [profileImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [profileImageView.layer setBorderWidth: 1.0];
    
    UILabel *userName = (UILabel *)[cell viewWithTag:2];
    
    if (member.completedRegistration) {
        profileImageView.image = member.profileImage;
        userName.textColor = [UIColor blackColor];
        userName.text = [NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName];
        
    } else {
        profileImageView.image = [UIImage imageNamed:@"profile_logo"];
        userName.textColor = [UIColor grayColor];
        userName.text = member.email;
    }
    
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:3];
    [deleteButton setTag:indexPath.row];
    //[deleteButton addTarget:self action:@selector(actionDeleteMember:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

@end
