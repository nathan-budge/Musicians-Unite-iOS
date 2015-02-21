//
//  GroupsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Navigation Drawer adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun

#import "UIViewController+ECSlidingViewController.h"
#import <Firebase/Firebase.h>

#import "AppConstant.h"

#import "GroupsTableViewController.h"
#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"

#import "Group.h"
#import "User.h"


@interface GroupsTableViewController ()

//Firebase references
@property (nonatomic) Firebase *ref;

//Array of user's groups
@property (nonatomic) NSMutableArray *groups;

//Object for current user
@property (nonatomic) User *user;

//Pan gesture for navigation drawer
@property (nonatomic, strong) UIPanGestureRecognizer *dynamicTransitionPanGesture;

//GroupID for tab bar controller
@property (nonatomic) Group *selectedGroup;

@end


@implementation GroupsTableViewController

#pragma mark - Lazy Instantiation

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}

-(NSMutableArray *)groups
{
    if (!_groups) {
        _groups = [[NSMutableArray alloc] init];
    }
    
    return _groups;
}

-(User *)user
{
    if (!_user) {
        _user = [[User alloc] init];
    }
    
    return _user;
}



#pragma mark - View Handling

- (void)viewDidLoad {
    [super viewDidLoad];

    //Set up navigation drawer
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    [self updateGroups];
    //[self updateUser];
}


#pragma mark - Firebase observer for user groups

- (void)updateGroups
{
    Firebase *userGroupsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups", self.ref.authData.uid]];
    
    //New groups and initial load
    [userGroupsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        
        Firebase *groupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]];
        
        [groupRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            NSDictionary *groupData = snapshot.value;
            
            Group *newGroup = [[Group alloc] init];
            
            for (NSString *memberID in groupData[@"members"]) {
            
                Firebase *memberRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", memberID]];
                
                [memberRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                    
                    User *newMember = [[User alloc] init];
                    
                    NSDictionary *memberData = snapshot.value;
                    
                    newMember.userID = snapshot.key;
                    newMember.firstName = memberData[@"first_name"];
                    newMember.lastName = memberData[@"last_name"];
                    newMember.email = memberData[@"email"];
                    
                    if ([memberData[@"completed_registration"] isEqual:@YES]) {
                        newMember.completedRegistration = YES;
                    } else {
                        newMember.completedRegistration = NO;
                    }
                
                    [newGroup addMember:newMember];
                }];
            }
            
            newGroup.groupID = groupID;
            newGroup.name = groupData[@"name"];
            
            [self.groups addObject:newGroup];
            [self.tableView reloadData];
        }];
        
        
        //Listen for changes to Group
        [groupRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
            
            NSLog(@"Something changed");

            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
            NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
            
            Group *changedGroup = [group objectAtIndex:0];
        
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                
                NSDictionary *groupData = snapshot.value;
                
                NSMutableArray *newMembers = [[NSMutableArray alloc] init];
                
                for (NSString *memberID in groupData[@"members"]) {
                    
                    Firebase *memberRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", memberID]];
                    
                    [memberRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                        
                        User *newMember = [[User alloc] init];
                        
                        NSDictionary *memberData = snapshot.value;
                        
                        newMember.userID = snapshot.key;
                        newMember.firstName = memberData[@"first_name"];
                        newMember.lastName = memberData[@"last_name"];
                        newMember.email = memberData[@"email"];
                        
                        if ([memberData[@"completed_registration"] isEqual:@YES]) {
                            newMember.completedRegistration = YES;
                        } else {
                            newMember.completedRegistration = NO;
                        }
                        
                        [newMembers addObject:newMember];
                    }];
                }
                
                [changedGroup.members removeAllObjects];
                for (User *member in newMembers) {
                    [changedGroup addMember:member];
                }
                
                changedGroup.name = snapshot.value[@"name"];
                                
                //[self.groups replaceObjectAtIndex:index withObject:updatedGroup];
                [self.tableView reloadData];
                
            }];
        }];
    }];
    
    //Listen for group removal
    [userGroupsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", snapshot.key];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        [self.groups removeObject:[group objectAtIndex:0]];
        [self.tableView reloadData];
        
    }];
}

-(void)updateUser
{
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.ref.authData.uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *userData = snapshot.value;
        
        self.user.userID = self.ref.authData.uid;
        self.user.firstName = userData[@"first_name"];
        self.user.lastName = userData[@"last_name"];
        self.user.email = self.ref.authData.providerData[@"email"];
    }];
}


#pragma mark - Navigation Drawer

- (IBAction)actionDrawerToggle:(id)sender {
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showGroupTabs"]) {
        GroupTabBarController *destViewController = segue.destinationViewController;
        destViewController.group = self.selectedGroup;
        
        for (User *user in self.selectedGroup.members) {
            NSLog(@"%@", user.email);
        }
        
        
    } else if ([segue.identifier isEqualToString:@"newGroup"]) {
        GroupDetailViewController *destViewController = segue.destinationViewController;
        destViewController.group = nil;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.groups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    Group *group = [self.groups objectAtIndex:indexPath.row];
    cell.textLabel.text = group.name;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedGroup = [self.groups objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"showGroupTabs" sender:nil];
}

@end
