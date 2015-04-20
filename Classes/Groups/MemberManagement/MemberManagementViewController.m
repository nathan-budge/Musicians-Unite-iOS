//
//  MemberManagementViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "MemberManagementViewController.h"

#import "User.h"
#import "Group.h"
#import "MessageThread.h"
#import "Message.h"


@interface MemberManagementViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;

@property (weak, nonatomic) IBOutlet UIButton *buttonConfirm;
@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITableView *memberTableView;

@property (nonatomic) NSMutableArray *members;
@property (nonatomic) NSMutableArray *membersToRemove;

@property (nonatomic, weak) SharedData *sharedData;

@end


@implementation MemberManagementViewController

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

-(NSMutableArray *)members
{
    if (!_members) {
        _members = [[NSMutableArray alloc] init];
    }
    return _members;
}

-(NSMutableArray *)membersToRemove
{
    if (!_membersToRemove) {
        _membersToRemove = [[NSMutableArray alloc] init];
    }
    return _membersToRemove;
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
    
    if(self.group.groupID)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSaveGroup)];
        self.buttonConfirm.hidden = YES;
        self.members = [NSMutableArray arrayWithArray:self.group.members];
    }
    else
    {
        self.buttonConfirm.hidden = NO;
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    self.memberTableView.contentInset = UIEdgeInsetsMake(-35.0f, 0.0f, 0.0f, 0.0f);
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionAddMemberToTableView:(id)sender
{
    [SVProgressHUD showWithStatus:@"Adding member..." maskType:SVProgressHUDMaskTypeBlack];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.email=%@", self.fieldEmail.text];
    NSArray *existingMember = [self.members filteredArrayUsingPredicate:predicate];
    
    if (existingMember.count > 0)
    {
        self.fieldEmail.text = @"";
        [SVProgressHUD showErrorWithStatus:@"Member already exists" maskType:SVProgressHUDMaskTypeBlack];
    }
    else if (![Utilities validateEmail:self.fieldEmail.text]|| [self.fieldEmail.text isEqualToString:self.ref.authData.providerData[@"email"]])
    {
        self.fieldEmail.text = @"";
        [SVProgressHUD showErrorWithStatus:@"Invalid email" maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        [self addMemberToTableView];
        [self dismissKeyboard];
    }
}

-(void)addMemberToTableView
{
    [[[self.userRef queryOrderedByChild:@"email"] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        User *newMember = [[User alloc] init];
        
        if ([snapshot.value isEqual:[NSNull null]])
        {
            newMember.completedRegistration = NO;
            newMember.email = self.fieldEmail.text;
        }
        else
        {
            NSDictionary *userData = snapshot.value;
            NSString *userID = [userData allKeys][0];
            
            newMember.userID = userID;
            newMember.email = userData[userID][@"email"];
            
            if ([userData[userID][@"completed_registration"] isEqual:@YES])
            {
                newMember.completedRegistration = YES;
                newMember.firstName = userData[userID][@"first_name"];
                newMember.lastName = userData[userID][@"last_name"];
                newMember.profileImage = [Utilities decodeBase64ToImage:userData[userID][@"profile_image"]];
            }
            else
            {
                newMember.completedRegistration = NO;
                newMember.email = self.fieldEmail.text;
            }
        }
        
        [self.members addObject:newMember];
        
        self.fieldEmail.text = @"";
        [self.memberTableView reloadData];
        
        [SVProgressHUD showSuccessWithStatus:@"Member Added" maskType:SVProgressHUDMaskTypeBlack];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (IBAction)actionCreateGroup:(id)sender
{
    Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
    
    NSDictionary *newGroup = @{
                               @"name":self.group.name,
                               @"profile_image":[Utilities encodeImageToBase64:self.group.profileImage],
                               };
    
    [groupRef setValue:newGroup];
    
    [[self.userRef childByAppendingPath:[NSString stringWithFormat:@"%@/groups", self.ref.authData.uid]] updateChildValues:@{groupRef.key:@YES}];
    [[groupRef childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
    
    [self addMembers:self.members toGroup:groupRef];
    
    dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self dismissKeyboard];
    });
}

-(void)actionSaveGroup
{
    [SVProgressHUD showWithStatus:@"Saving your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    if ([self.group.members count] > 0)
    {
        for (User *member in self.group.members) {
        
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", member.userID];
            NSArray *foundMember = [self.members filteredArrayUsingPredicate:predicate];
            
            if ([foundMember count] > 0) //Membership didn't change
            {
                [self.members removeObject:[foundMember objectAtIndex:0]];
            }
            else // User was removed from a group
            {
                [self.membersToRemove addObject:member];
            }
        }
    }
    
    if (self.membersToRemove.count > 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Removing users will remove their data from the group. Would you like to continue?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alert show];
    }
    else if ([self.members count] > 0) //User was added to a group
    {
        Firebase *groupRef =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.group.groupID]];
        [self addMembers:self.members toGroup:groupRef];
        
        [SVProgressHUD showSuccessWithStatus:@"Group saved" maskType:SVProgressHUDMaskTypeBlack];
        [self.navigationController popViewControllerAnimated:YES];
        
        [self dismissKeyboard];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        for (User *member in self.membersToRemove) {
        
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", self.group.groupID, member.userID]] removeValue];
            [[self.userRef childByAppendingPath:[NSString stringWithFormat:@"%@/groups/%@", member.userID, self.group.groupID]] removeValue];
            
            if (!member.completedRegistration) //Remove temp users that do not belong to any group
            {
                [Utilities removeEmptyTempUsers:member.userID withRef:self.ref];
            }
        }
        
        if ([self.members count] > 0) //User was added to a group
        {
            Firebase *groupRef =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.group.groupID]];
            [self addMembers:self.members toGroup:groupRef];
        }
        
        [SVProgressHUD showSuccessWithStatus:@"Group saved" maskType:SVProgressHUDMaskTypeBlack];
        [self.navigationController popViewControllerAnimated:YES];
        
        [self dismissKeyboard];
    }
}

- (void) addMembers: (NSMutableArray *)members toGroup:(Firebase *)groupRef
{
    for (User *member in members) {
        
        if (member.userID)
        {
            [[groupRef childByAppendingPath:@"members"] updateChildValues:@{member.userID:@YES}];
            [[[self.userRef childByAppendingPath:member.userID] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
        }
        else
        {
            NSDictionary *newTempMember = @{
                                            @"email":member.email,
                                            @"completed_registration":@NO
                                            };
            
            Firebase *tempMemberRef = [self.userRef childByAutoId];
            
            [tempMemberRef setValue:newTempMember];
            [[tempMemberRef childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
            [[groupRef childByAppendingPath:@"members"] updateChildValues:@{tempMemberRef.key:@YES}];
        }
    }
}

-(void)actionDeleteMember:(id)sender
{
    UIButton *btn =(UIButton*)sender;
    [self.members removeObjectAtIndex:btn.tag];
    [self.memberTableView reloadData];
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    
    User *member = [self.members objectAtIndex:indexPath.row];
    
    //Get subviews
    UIImageView *profileImageView = (UIImageView *)[cell viewWithTag:1];
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
    profileImageView.layer.masksToBounds = YES;
    [profileImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [profileImageView.layer setBorderWidth: 1.0];
    
    UILabel *userName = (UILabel *)[cell viewWithTag:2];
    
    //Set subviews
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
    [deleteButton addTarget:self action:@selector(actionDeleteMember:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

@end
