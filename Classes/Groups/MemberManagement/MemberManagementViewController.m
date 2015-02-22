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

#import "MemberManagementViewController.h"

#import "User.h"


@interface MemberManagementViewController ()

//Firebase reference
@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UIButton *buttonConfirm;

@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;

@property (weak, nonatomic) IBOutlet UITableView *memberTableView;

@property (nonatomic) NSMutableArray *members;

@end


@implementation MemberManagementViewController

#pragma mark - Lazy instatination

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}

-(NSMutableArray *)members
{
    if (!_members) {
        _members = [[NSMutableArray alloc] init];
    }
    
    return _members;
}


#pragma mark - View handling

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.group.groupID) {
        [self.buttonConfirm setTitle:@"Save" forState:UIControlStateNormal];
        
        for (User *member in self.group.members) {
            if (![member.userID isEqualToString:self.ref.authData.uid]) {
                [self.members addObject:member];
            }
        }

    } else {
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
    }
    
    //Add tap gesture for dismissing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}



#pragma mark - Buttons

- (IBAction)actionAddMember:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Adding member..." maskType:SVProgressHUDMaskTypeBlack];
    
    if (![Utilities validateEmail:self.fieldEmail.text]|| [self.fieldEmail.text isEqualToString:self.ref.authData.providerData[@"email"]]) {
        
        self.fieldEmail.text = @"";
        
        [SVProgressHUD showErrorWithStatus:@"Invalid email" maskType:SVProgressHUDMaskTypeBlack];
        
        //Deal with case where user inputs email for current user
        
    } else{
    
        Firebase *userRef = [self.ref childByAppendingPath:@"users"];
        
        [[[userRef queryOrderedByChild:@"email"] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            User *newMember = [[User alloc] init];
            
            if (![snapshot.value isEqual:[NSNull null]]) { //If user exists
                
                NSDictionary *userData = snapshot.value;
                NSString *userID = [userData allKeys][0];
                
                newMember.userID = userID;
                newMember.email = userData[userID][@"email"];
                
                if ([userData[userID][@"completed_registration"] isEqual:@YES]) {
                    newMember.firstName = userData[userID][@"first_name"];
                    newMember.lastName = userData[userID][@"last_name"];
                    newMember.completedRegistration = YES;
                }
                else {
                    newMember.email = self.fieldEmail.text;
                    newMember.completedRegistration = NO;
                }
        
            } else {
                newMember.email = self.fieldEmail.text;
                newMember.completedRegistration = NO;
            }
            
            [self.members addObject:newMember];
            
            self.fieldEmail.text = @"";
            [self.memberTableView reloadData];
            [SVProgressHUD showSuccessWithStatus:@"Member Added" maskType:SVProgressHUDMaskTypeBlack];
        }];
    }
}


- (IBAction)actionConfirm:(id)sender {
    
    Firebase *userRef = [self.ref childByAppendingPath:@"users"];
    
    if (self.group.groupID) {  //Edit existing group
        
        [SVProgressHUD showWithStatus:@"Saving your group..." maskType:SVProgressHUDMaskTypeBlack];
        
        for (User *member in self.group.members) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", member.userID];
            NSArray *foundMember = [self.members filteredArrayUsingPredicate:predicate];
            
            if ([foundMember count] > 0) { //if user found
                [self.members removeObject:[foundMember objectAtIndex:0]];
            } else if (![member.userID isEqualToString:self.ref.authData.uid]) {
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", self.group.groupID, member.userID]] removeValue];
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups/%@", member.userID, self.group.groupID]] removeValue];
            }
            
            if ([self.members count] > 0) { //Add new members to group
                Firebase *oldGroup =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.group.groupID]];
                [self addGroupMembers:self.members withUserRef:userRef andGroupRef:oldGroup];
            }
            
            [SVProgressHUD showSuccessWithStatus:@"Group saved" maskType:SVProgressHUDMaskTypeBlack];
        }
        
    } else {  //Create new group
        
        [SVProgressHUD showWithStatus:@"Creating your group..." maskType:SVProgressHUDMaskTypeBlack];
        
        Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
        
        //Add New Group
        [groupRef setValue:@{@"name":self.group.name}];
        
        //Add group creator to member lists
        [[[userRef childByAppendingPath:self.ref.authData.uid] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
        [[groupRef childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
        
        //Deal with the rest of the members
        [self addGroupMembers:self.members withUserRef:userRef andGroupRef:groupRef];
        
        [SVProgressHUD showSuccessWithStatus:@"Group created" maskType:SVProgressHUDMaskTypeBlack];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}


- (void) addGroupMembers: (NSMutableArray *)members withUserRef:(Firebase *)userRef andGroupRef:(Firebase *)groupRef
{
    for (User *member in members) {
        
        if (member.userID) { //If user exists
            
            [[groupRef childByAppendingPath:@"members"] updateChildValues:@{member.userID:@YES}];
            [[[userRef childByAppendingPath:member.userID] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];

        } else {
            
            NSDictionary *newTempMember = @{
                                            @"email":member.email,
                                            @"completed_registration":@NO
                                            };
            
            Firebase *tempMemberRef = [userRef childByAutoId];
            
            [tempMemberRef setValue:newTempMember];
            [[tempMemberRef childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
            [[groupRef childByAppendingPath:@"members"] updateChildValues:@{tempMemberRef.key:@YES}];
        }
    }
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}


-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}


-(void)deleteMember:(id)sender
{
    UIButton *btn =(UIButton*)sender;
    
    [self.members removeObjectAtIndex:btn.tag];
    
    [self.memberTableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.members count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    User *member = [self.members objectAtIndex:indexPath.row];
    
    if (member.completedRegistration) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName];
    } else {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.text = member.email;
    }
    
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    deleteButton.frame = CGRectMake(325, 20, 20, 20);
    [deleteButton setTitle:@"X" forState:UIControlStateNormal];
    [deleteButton setTag:indexPath.row];
    [deleteButton addTarget:self action:@selector(deleteMember:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:deleteButton];
    
    return cell;
}

@end
