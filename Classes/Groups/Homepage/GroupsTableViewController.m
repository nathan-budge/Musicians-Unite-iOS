//
//  GroupsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Navigation Drawer adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun
//

#import "UIViewController+ECSlidingViewController.h"
#import <Firebase/Firebase.h>

#import "AppConstant.h"

#import "GroupsTableViewController.h"
#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"

#import "User.h"
#import "Group.h"


@interface GroupsTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) NSMutableArray *groups;

@property (nonatomic) User *user;

@property (nonatomic, strong) UIPanGestureRecognizer *dynamicTransitionPanGesture;

@property (nonatomic) Group *selectedGroup;

@property (nonatomic) BOOL initialLoad;

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    self.initialLoad = YES;
    [self loadGroups];
    [self loadUser];
}



#pragma mark - Load Groups

- (void)loadGroups
{
    Firebase *userGroupsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups", self.ref.authData.uid]];
    
    [self attachListenerForAddedGroupsToUser:userGroupsRef]; //Also used for loading groups initially
    
    [self attachListenerForRemovedGroupsToUser:userGroupsRef];
    
}


-(void)attachListenerForAddedGroupsToUser:(Firebase *)userGroupsRef
{
    [userGroupsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        
        Firebase *groupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]];
        
        Group *newGroup = [[Group alloc] init];
        
        [self loadGroupData:groupRef withGroupID:groupID intoGroup:newGroup];
        [self attachListenerForAddedMembersToGroup:groupRef withGroupID:groupID andNewGroup:newGroup];
        [self attachListenerForRemovedMembersToGroup:groupRef withGroupID:groupID];
        [self attachListenerForChangesToNameOrPictureToGroup:groupRef withGroupID:groupID];
    }];
}


-(void)loadGroupData:(Firebase *)groupRef withGroupID:(NSString *)groupID intoGroup:(Group *)newGroup
{
    [groupRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *groupData = snapshot.value;
    
        newGroup.groupID = groupID;
        newGroup.name = groupData[@"name"];
        
        [self.groups addObject:newGroup];
        
        [self.tableView reloadData];
        
        self.initialLoad = NO;
    }];
}


-(void)attachListenerForAddedMembersToGroup:(Firebase *)groupRef withGroupID:(NSString *)groupID andNewGroup:(Group *)newGroup
{
    [[groupRef childByAppendingPath:@"members"] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        Group *changedGroup;
        NSString *newMemberID = snapshot.key;
        
        if (self.initialLoad) {
            changedGroup = newGroup;
        } else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
            NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
            changedGroup = [group objectAtIndex:0];
        }
        
        Firebase *memberRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", newMemberID]];
        
        [self addMember:memberRef toGroup:changedGroup];
        [self.tableView reloadData];
    }];
}


-(void)addMember:(Firebase *)memberRef toGroup:(Group *)group
{
    [memberRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *memberData = snapshot.value;
        
        User *newMember = [[User alloc] init];
        
        newMember.userID = snapshot.key;
        newMember.email = memberData[@"email"];
        
        if ([memberData[@"completed_registration"] isEqual:@YES]) {
            newMember.completedRegistration = YES;
            newMember.firstName = memberData[@"first_name"];
            newMember.lastName = memberData[@"last_name"];
        }else {
            newMember.completedRegistration = NO;
        }
        
        [group addMember:newMember];
    }];
}


-(void)attachListenerForRemovedMembersToGroup:(Firebase *)groupRef withGroupID:(NSString *)groupID
{
    [[groupRef childByAppendingPath:@"members"] observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        if ([group count] > 0) {
            Group *changedGroup = [group objectAtIndex:0];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", snapshot.key];
            NSArray *member = [changedGroup.members filteredArrayUsingPredicate:predicate];
            
            [changedGroup removeMember:[member objectAtIndex:0]];

            [self.tableView reloadData];
        }
    }];
}


-(void)attachListenerForChangesToNameOrPictureToGroup:(Firebase *)groupRef withGroupID:(NSString *)groupID
{
    [groupRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        if ([snapshot.key isEqualToString:@"name"]) {
            Group *changedGroup = [group objectAtIndex:0];
            
            NSString *newName = snapshot.value;
            changedGroup.name = newName;
            
            [self.tableView reloadData];
        }
    }];
}


-(void)attachListenerForRemovedGroupsToUser:(Firebase *)userGroupsRef
{
    [userGroupsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        [self.groups removeObject:[group objectAtIndex:0]];
        [self.tableView reloadData];
        
    }];
}



#pragma mark - Load User

-(void)loadUser
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

- (IBAction)actionDrawerToggle:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}



#pragma mark - Prepare for segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showGroupTabs"]) {
        GroupTabBarController *destViewController = segue.destinationViewController;
        destViewController.group = self.selectedGroup;
    } else if ([segue.identifier isEqualToString:@"newGroup"]) {
        GroupDetailViewController *destViewController = segue.destinationViewController;
        destViewController.group = nil;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.groups count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil) {
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
