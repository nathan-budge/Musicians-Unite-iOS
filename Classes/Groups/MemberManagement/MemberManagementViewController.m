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
#import "Group.h"


@interface MemberManagementViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) Firebase *userRef;

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



#pragma mark - View Handling

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.group.groupID) {
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSaveGroup)];
        
        self.buttonConfirm.hidden = YES;
        
        for (User *member in self.group.members) {
            if (![member.userID isEqualToString:self.ref.authData.uid]) {
                [self.members addObject:member];
            }
        }
    } else {
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}



#pragma mark - Buttons

- (IBAction)actionAddMember:(id)sender
{
    [SVProgressHUD showWithStatus:@"Adding member..." maskType:SVProgressHUDMaskTypeBlack];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.email=%@", self.fieldEmail.text];
    NSArray *existingMember = [self.members filteredArrayUsingPredicate:predicate];
    
    if ([existingMember count] > 0) {
        
        self.fieldEmail.text = @"";
        
        [SVProgressHUD showErrorWithStatus:@"Member already exists" maskType:SVProgressHUDMaskTypeBlack];
        
    } else if (![Utilities validateEmail:self.fieldEmail.text]|| [self.fieldEmail.text isEqualToString:self.ref.authData.providerData[@"email"]]){
        
        self.fieldEmail.text = @"";
        
        [SVProgressHUD showErrorWithStatus:@"Invalid email" maskType:SVProgressHUDMaskTypeBlack];
        
    } else{
        [self addMember];
        [self dismissKeyboard];
    }
}


-(void)addMember
{
    Firebase *userRef = [self.ref childByAppendingPath:@"users"];
    
    [[[userRef queryOrderedByChild:@"email"] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        User *newMember = [[User alloc] init];
        
        if (![snapshot.value isEqual:[NSNull null]]) {
            
            NSDictionary *userData = snapshot.value;
            NSString *userID = [userData allKeys][0];
            
            newMember.userID = userID;
            newMember.email = userData[userID][@"email"];
            
            if ([userData[userID][@"completed_registration"] isEqual:@YES]) {
                newMember.completedRegistration = YES;
                newMember.firstName = userData[userID][@"first_name"];
                newMember.lastName = userData[userID][@"last_name"];
            }
            else {
                newMember.completedRegistration = NO;
                newMember.email = self.fieldEmail.text;
            }
            
        } else {
            
            newMember.email = self.fieldEmail.text;
            newMember.completedRegistration = NO;
            
        }
        
        [self.members addObject:newMember];
        
        self.fieldEmail.text = @"";
        [self.memberTableView reloadData];
        
        [SVProgressHUD showSuccessWithStatus:@"Member Added" maskType:SVProgressHUDMaskTypeBlack];
        
    } withCancelBlock:^(NSError *error) {
        
        NSLog(@"%@", error.description);
        
    }];
}


- (IBAction)actionCreateGroup:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Creating your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
    
    [groupRef setValue:@{@"name":self.group.name}];
    
    [[[self.userRef childByAppendingPath:self.ref.authData.uid] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
    [[groupRef childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
    
    [self addGroupMembers:self.members withUserRef:self.userRef andGroupRef:groupRef];
    
    [SVProgressHUD showSuccessWithStatus:@"Group created" maskType:SVProgressHUDMaskTypeBlack];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [self dismissKeyboard];
}


-(void)actionSaveGroup
{
    [SVProgressHUD showWithStatus:@"Saving your group..." maskType:SVProgressHUDMaskTypeBlack];
    
    for (User *member in self.group.members) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", member.userID];
        NSArray *foundMember = [self.members filteredArrayUsingPredicate:predicate];
        
        if ([foundMember count] > 0) {
            
            [self.members removeObject:[foundMember objectAtIndex:0]];
            
        } else if (![member.userID isEqualToString:self.ref.authData.uid]) {
            
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members/%@", self.group.groupID, member.userID]] removeValue];
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups/%@", member.userID, self.group.groupID]] removeValue];
            
            if (!member.completedRegistration) {
                [Utilities removeEmptyTempUsers:member.userID withRef:self.ref];
            }
            
        }
        
        if ([self.members count] > 0) {
            Firebase *oldGroup =[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", self.group.groupID]];
            [self addGroupMembers:self.members withUserRef:self.userRef andGroupRef:oldGroup];
        }
        
        [self.memberTableView reloadData];
        
        [SVProgressHUD showSuccessWithStatus:@"Group saved" maskType:SVProgressHUDMaskTypeBlack];
    }
    
    [self dismissKeyboard];
}


- (void) addGroupMembers: (NSMutableArray *)members withUserRef:(Firebase *)userRef andGroupRef:(Firebase *)groupRef
{
    for (User *member in members) {
        
        if (member.userID) {
            
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


-(void)actionDeleteMember:(id)sender
{
    UIButton *btn =(UIButton*)sender;
    
    [self.members removeObjectAtIndex:btn.tag];
    
    [self.memberTableView reloadData];
}



#pragma mark - Keyboard Handling

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    
    return YES;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.members count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
    [deleteButton addTarget:self action:@selector(actionDeleteMember:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:deleteButton];
    
    return cell;
}

@end
