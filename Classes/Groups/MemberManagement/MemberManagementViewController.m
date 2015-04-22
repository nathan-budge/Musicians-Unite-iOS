//
//  MemberManagementViewController.m
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

#import "MemberManagementViewController.h"

#import "User.h"
#import "Group.h"
#import "MessageThread.h"
#import "Message.h"


@interface MemberManagementViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;

@property (nonatomic) NSMutableArray *members;
@property (nonatomic) NSMutableArray *membersToRemove;

@property (nonatomic, weak) SharedData *sharedData;

@property (weak, nonatomic) IBOutlet UIButton *buttonConfirm;
@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITableView *memberTableView;

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
        _userRef = [self.ref childByAppendingPath:kUsersFirebaseNode];
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
        self.buttonConfirm.hidden = YES;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSaveGroup)];
        self.members = [NSMutableArray arrayWithArray:self.group.members];
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        self.buttonConfirm.hidden = NO;
        [self.buttonConfirm setTitle:kCreateButtonTitle forState:UIControlStateNormal];
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
    [SVProgressHUD showWithStatus:kAddingMemberProgressMessage maskType:SVProgressHUDMaskTypeBlack];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.email=%@", self.fieldEmail.text];
    NSArray *existingMember = [self.members filteredArrayUsingPredicate:predicate];
    
    if (existingMember.count > 0)
    {
        self.fieldEmail.text = @"";
        [SVProgressHUD showErrorWithStatus:kMemberAlreadyExistsError maskType:SVProgressHUDMaskTypeBlack];
    }
    else if (![Utilities validateEmail:self.fieldEmail.text]|| [self.fieldEmail.text isEqualToString:self.sharedData.user.email])
    {
        self.fieldEmail.text = @"";
        [SVProgressHUD showErrorWithStatus:kInvalidEmailError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        [self addMemberToTableView];
        [self dismissKeyboard];
    }
}

-(void)addMemberToTableView
{
    [[[self.userRef queryOrderedByChild:kUserEmailFirebaseField] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
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
            newMember.email = userData[userID][kUserEmailFirebaseField];
            
            if ([userData[userID][kUserCompletedRegistrationFirebaseField] isEqual:@YES])
            {
                newMember.completedRegistration = YES;
                newMember.firstName = userData[userID][kUserFirstNameFirebaseField];
                newMember.lastName = userData[userID][kUserLastNameFirebaseField];
                newMember.profileImage = [Utilities decodeBase64ToImage:userData[userID][kProfileImageFirebaseField]];
            }
            else
            {
                newMember.completedRegistration = NO;
                newMember.email = self.fieldEmail.text;
            }
        }
        
        [self.members addObject:newMember];
        
        self.fieldEmail.text = @"";
        [SVProgressHUD dismiss];
        [self.memberTableView reloadData];
        
        if (self.group.groupID)
        {
            self.navigationItem.rightBarButtonItem.enabled = [self enableSave];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (IBAction)actionCreateGroup:(id)sender
{
    Firebase *groupRef = [[self.ref childByAppendingPath:kGroupsFirebaseNode] childByAutoId];
    
    NSDictionary *newGroup = @{
                               kGroupNameFirebaseField:self.group.name,
                               kProfileImageFirebaseField:[Utilities encodeImageToBase64:self.group.profileImage],
                               };
    
    [groupRef setValue:newGroup];
    
    [[self.userRef childByAppendingPath:[NSString stringWithFormat:@"%@/%@", self.sharedData.user.userID, kGroupsFirebaseNode]] updateChildValues:@{groupRef.key:@YES}];
    [[groupRef childByAppendingPath:kMembersFirebaseNode] updateChildValues:@{self.sharedData.user.userID:@YES}];
    
    [self addMembers:self.members toGroup:groupRef];
    
    dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self dismissKeyboard];
    });
}

-(void)actionSaveGroup
{
    for (User *member in self.group.members) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", member.userID];
        NSArray *foundMember = [self.members filteredArrayUsingPredicate:predicate];
        
        if (foundMember.count > 0) //Membership didn't change
        {
            [self.members removeObject:[foundMember objectAtIndex:0]];
        }
        else // User was removed from a group
        {
            [self.membersToRemove addObject:member];
        }
    }
    
    if (self.membersToRemove.count > 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:kDeleteMemberAlertMessage delegate:self cancelButtonTitle:kCancelButtonTitle otherButtonTitles:kConfirmButtonTitle, nil];
        [alert show];
    }
    else if (self.members.count > 0) //User was added to a group
    {
        Firebase *groupRef =[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kGroupsFirebaseNode, self.group.groupID]];
        [self addMembers:self.members toGroup:groupRef];
        
        [self groupSavedNotification];
    }
    else
    {
        [self groupSavedNotification];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        for (User *member in self.membersToRemove) {
        
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kMembersFirebaseNode, member.userID]] removeValue];
            [[self.userRef childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", member.userID, kGroupsFirebaseNode, self.group.groupID]] removeValue];
            
            if (!member.completedRegistration) //Remove temp users that do not belong to any group
            {
                [Utilities removeEmptyTempUsers:member.userID withRef:self.ref];
            }
        }
        
        if (self.members.count > 0) //User was added to a group
        {
            Firebase *groupRef =[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kGroupsFirebaseNode, self.group.groupID]];
            [self addMembers:self.members toGroup:groupRef];
        }
        
        [self groupSavedNotification];
    }
}

- (void) addMembers: (NSMutableArray *)members toGroup:(Firebase *)groupRef
{
    for (User *member in members) {
        
        if (member.userID)
        {
            [[groupRef childByAppendingPath:kMembersFirebaseNode] updateChildValues:@{member.userID:@YES}];
            [[self.userRef childByAppendingPath:[NSString stringWithFormat:@"%@/%@", member.userID, kGroupsFirebaseNode]] updateChildValues:@{groupRef.key:@YES}];
        }
        else
        {
            NSDictionary *newTempMember = @{
                                            kUserEmailFirebaseField:member.email,
                                            kUserCompletedRegistrationFirebaseField:@NO
                                            };
            
            Firebase *tempMemberRef = [self.userRef childByAutoId];
            
            [tempMemberRef setValue:newTempMember];
            [[tempMemberRef childByAppendingPath:kGroupsFirebaseNode] updateChildValues:@{groupRef.key:@YES}];
            [[groupRef childByAppendingPath:kMembersFirebaseNode] updateChildValues:@{tempMemberRef.key:@YES}];
        }
    }
}

-(void)actionDeleteMember:(id)sender
{
    UIButton *btn =(UIButton*)sender;
    [self.members removeObjectAtIndex:btn.tag];
    [self.memberTableView reloadData];
    
    if (self.group.groupID)
    {
        self.navigationItem.rightBarButtonItem.enabled = [self enableSave];
    }
}

-(void)groupSavedNotification
{
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
    
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissKeyboard];
}

- (BOOL)enableSave
{
    if (self.group.members.count != self.members.count)
    {
        return YES;
    }
    else
    {
        BOOL membersMatch = NO;
        for (User *member in self.members) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.email=%@", member.email];
            NSArray *existingMember = [self.group.members filteredArrayUsingPredicate:predicate];
            
            if (existingMember.count > 0)
            {
                membersMatch = YES;
            }
            else
            {
                membersMatch = NO;
                break;
            }
        }
        
        return !membersMatch;
    }
    
    return NO;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserCellIdentifier];
    
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
        profileImageView.image = [UIImage imageNamed:kProfileLogoImage];
        userName.textColor = [UIColor grayColor];
        userName.text = member.email;
    }
    
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:3];
    [deleteButton setTag:indexPath.row];
    [deleteButton addTarget:self action:@selector(actionDeleteMember:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

@end
