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
#import "MemberManagementViewController.h"

@interface MemberManagementViewController ()

//Firebase reference
@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UIButton *buttonConfirm;
@property (weak, nonatomic) IBOutlet UITextField *fieldEmail;
@property (weak, nonatomic) IBOutlet UITableView *memberTableView;

//Array of members
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
    
    NSLog(@"%@", self.groupName);
    
    if ([self.groupName isEqualToString:@""]) {
        [self.buttonConfirm setTitle:@"Save" forState:UIControlStateNormal];
    } else {
        [self.buttonConfirm setTitle:@"Create" forState:UIControlStateNormal];
    }
    
    //Add tap gesture for dismissing the keyboard
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}




#pragma mark - Buttons

- (IBAction)actionAddMember:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Adding member..." maskType:SVProgressHUDMaskTypeBlack];
    
    if (![self validateEmail:self.fieldEmail.text]|| [self.fieldEmail.text isEqualToString:self.ref.authData.providerData[@"email"]]) {
        
        self.fieldEmail.text = @"";
        
        [SVProgressHUD showErrorWithStatus:@"Invalid email" maskType:SVProgressHUDMaskTypeBlack];
        
    }

    else{
        
        Firebase *userRef = [self.ref childByAppendingPath:@"users"];
        
        [[[userRef queryOrderedByChild:@"email"] queryEqualToValue:self.fieldEmail.text] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
            
            if (![snapshot.value isEqual:[NSNull null]]) { //If user exists
                
                NSString *userID = [snapshot.value allKeys][0];
                
                if ([snapshot.value[userID][@"completed_registration"] isEqual:@YES]) {
                    
                    NSString *name = [NSString stringWithFormat:@"%@ %@", snapshot.value[userID][@"first_name"], snapshot.value[userID][@"last_name"]];
                    [memberData setObject:name forKey:@"user_name"];
                }
                else {
                    [memberData setObject:self.fieldEmail.text forKey:@"user_email"];
                }
                
                [memberData setObject:userID forKey:@"user_id"];
                [memberData setObject:snapshot.value[userID][@"completed_registration"] forKey:@"completed_registration"];
                
                NSLog(@"%@", memberData);
                
                [self.members addObject:memberData];
                
            } else {
                
                [memberData setObject:@"" forKey:@"user_id"];
                [memberData setObject:self.fieldEmail.text forKey:@"user_email"];
                [memberData setObject:@NO forKey:@"completed_registration"];
                [self.members addObject:memberData];
            }
            
            self.fieldEmail.text = @"";
            [self.memberTableView reloadData];
            [SVProgressHUD showSuccessWithStatus:@"Member Added" maskType:SVProgressHUDMaskTypeBlack];
        }];
    }
}

- (BOOL)validateEmail:(NSString *)emailStr {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailStr];
}


- (IBAction)actionConfirm:(id)sender {
    if (!self.groupName) {
        //Group Settings Save
    } else {
        
        [SVProgressHUD showWithStatus:@"Creating your group..." maskType:SVProgressHUDMaskTypeBlack];
        
        Firebase *groupRef = [[self.ref childByAppendingPath:@"groups"] childByAutoId];
        Firebase *userRef = [self.ref childByAppendingPath:@"users"];
        
        //Add New Group
        [groupRef setValue:@{@"name":self.groupName}];
        
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
    for (NSMutableDictionary *member in members) {
        
        if ([member[@"user_id"] isEqualToString:@""]) { //If user does not exist
            
            NSDictionary *newTempMember = @{
                                            @"email":member[@"user_email"],
                                            @"completed_registration":@NO
                                            };
            
            Firebase *tempMemberRef = [userRef childByAutoId];
            
            [tempMemberRef setValue:newTempMember];
            [[tempMemberRef childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
            [[groupRef childByAppendingPath:@"members"] updateChildValues:@{tempMemberRef.key:@YES}];
            
        } else {
            
            [[groupRef childByAppendingPath:@"members"] updateChildValues:@{member[@"user_id"]:@YES}];
            [[[userRef childByAppendingPath:member[@"user_id"]] childByAppendingPath:@"groups"] updateChildValues:@{groupRef.key:@YES}];
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
    
    NSMutableDictionary *member = [self.members objectAtIndex:indexPath.row];
    
    
    if ([member[@"completed_registration"] isEqual:@YES]) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = member[@"user_name"];
    } else {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.text = member[@"user_email"];
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
