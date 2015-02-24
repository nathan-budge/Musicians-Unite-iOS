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
#import "NavigationDrawerViewController.h"

#import "User.h"
#import "Group.h"
#import "MessageThread.h"


@interface GroupsTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) NSMutableArray *groups;

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

-(NSMutableArray *)childObservers
{
    if (!_childObservers) {
        _childObservers = [[NSMutableArray alloc] init];
    }
    
    return _childObservers;
    
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
    [self.childObservers addObject:userGroupsRef];
    
    [self attachListenerForAddedGroupsToUser:userGroupsRef]; //Also used for loading groups initially
    
    [self attachListenerForRemovedGroupsToUser:userGroupsRef];
}


-(void)attachListenerForAddedGroupsToUser:(Firebase *)userGroupsRef
{
    [userGroupsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        
        Firebase *groupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]];
        [self.childObservers addObject:groupRef];
        
        Group *newGroup = [[Group alloc] init];
        
        [self loadGroupData:groupRef withGroupID:groupID intoGroup:newGroup];
        
        [self attachListenerForAddedMembersToGroup:groupRef withGroupID:groupID andNewGroup:newGroup];
        [self attachListenerForRemovedMembersToGroup:groupRef withGroupID:groupID];
        
        [self attachListenerForAddedMessageThreadsToGroup:groupRef withGroupID:groupID andNewGroup:newGroup];
        
        [self attachListenerForChangesToNameOrPictureToGroup:groupRef withGroupID:groupID];
    }];
}


-(void)loadGroupData:(Firebase *)groupRef withGroupID:(NSString *)groupID intoGroup:(Group *)newGroup
{
    [groupRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *groupData = snapshot.value;
    
        newGroup.groupID = groupID;
        newGroup.name = groupData[@"name"];
        newGroup.profileImage = groupData[@"profile_image"];
        
        [self.groups addObject:newGroup];
        [self.user addGroup:newGroup];
        
        [self.tableView reloadData];
    }];
}


-(void)attachListenerForAddedMembersToGroup:(Firebase *)groupRef withGroupID:(NSString *)groupID andNewGroup:(Group *)newGroup
{
    Firebase *groupMembersRef = [groupRef childByAppendingPath:@"members"];
    [self.childObservers addObject:groupMembersRef];
    
    [groupMembersRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
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
        [self.childObservers addObject:memberRef];
        
        if (![newMemberID isEqualToString:self.ref.authData.uid]) {
             [self addMember:memberRef toGroup:changedGroup];
        }
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
            newMember.profileImage = memberData[@"profile_image"];
        }else {
            newMember.completedRegistration = NO;
        }
        
        [group addMember:newMember];
    }];
}


-(void)attachListenerForAddedMessageThreadsToGroup:(Firebase *)groupRef withGroupID:(NSString *)groupID andNewGroup:(Group *)newGroup
{
    Firebase *groupMessageThreadsRef = [groupRef childByAppendingPath:@"message_threads"];
    [self.childObservers addObject:groupMessageThreadsRef];
    
    [groupMessageThreadsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        Group *changedGroup;
        NSString *newMessageThreadID = snapshot.key;
        
        if (self.initialLoad) {
            changedGroup = newGroup;
        } else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
            NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
            changedGroup = [group objectAtIndex:0];
        }
        
        Firebase *messageThreadRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@", newMessageThreadID]];
        [self.childObservers addObject:messageThreadRef];
        
        [messageThreadRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            NSDictionary *messageThreadData = snapshot.value;
            
            if ([[messageThreadData[@"members"] allKeys] containsObject:self.ref.authData.uid]) {
                
                MessageThread *newMessageThread = [[MessageThread alloc] init];
                
                newMessageThread.messageThreadID = snapshot.key;
                [changedGroup addMessageThread:newMessageThread];
                
                [self attachListenerForAddedMembersToThread:messageThreadRef withThreadID:newMessageThread.messageThreadID andGroupID:changedGroup.groupID andNewGroup:newGroup];
            }
        }];
    }];
}


-(void)attachListenerForAddedMembersToThread:(Firebase *)messageThreadRef withThreadID:(NSString *)threadID andGroupID:(NSString *)groupID andNewGroup:(Group *)newGroup
{
    Firebase *messageMembersRef = [messageThreadRef childByAppendingPath:@"members"];
    [self.childObservers addObject:messageMembersRef];
    
    [messageMembersRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *memberID = snapshot.key;
        if (![memberID isEqualToString:self.ref.authData.uid]) {
            
            Group *changedGroup;
            
            if (self.initialLoad) {
                changedGroup = newGroup;
            } else {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
                NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
                changedGroup = [group objectAtIndex:0];
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.messageThreadID=%@", threadID];
            NSArray *messageThread = [changedGroup.messageThreads filteredArrayUsingPredicate:predicate];
            MessageThread *aMessageThread = [messageThread objectAtIndex:0];
            
            predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", memberID];
            NSArray *member= [changedGroup.members filteredArrayUsingPredicate:predicate];
            User *aMember = [member objectAtIndex:0];
            
            [aMessageThread addMember:aMember];
        }
    
    }];
    
}


-(void)attachListenerForRemovedMembersToGroup:(Firebase *)groupRef withGroupID:(NSString *)groupID
{
    Firebase *groupMembersRef = [groupRef childByAppendingPath:@"members"];
    [self.childObservers addObject:groupMembersRef];
    
    [groupMembersRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
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
        } else if ([snapshot.key isEqualToString:@"profile_image"]) {
            Group *changedGroup = [group objectAtIndex:0];
            
            NSString *newProfileImage = snapshot.value;
            changedGroup.profileImage = newProfileImage;
            
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
    Firebase *userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.ref.authData.uid]];
    [self.childObservers addObject:userRef];
    
    [self loadUserData:userRef];
    
    [self attachListenerForChangesToUser:userRef];
    
    NavigationDrawerViewController *navigationDrawerViewController = (NavigationDrawerViewController *)self.slidingViewController.underLeftViewController;
    navigationDrawerViewController.user = self.user;
    navigationDrawerViewController.childObservers = self.childObservers;
}


-(void)loadUserData:(Firebase *)userRef
{
    [userRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *userData = snapshot.value;
        
        self.user.userID = self.ref.authData.uid;
        self.user.firstName = userData[@"first_name"];
        self.user.lastName = userData[@"last_name"];
        self.user.email = self.ref.authData.providerData[@"email"];
        self.user.profileImage = userData[@"profile_image"];
    }];
    
}


-(void)attachListenerForChangesToUser:(Firebase *)userRef
{
    [userRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"first_name"]) {
            
            NSString *newFirstName = snapshot.value;
            self.user.firstName = newFirstName;
            
            [self.tableView reloadData];
        } else if ([snapshot.key isEqualToString:@"last_name"]) {
            NSString *newLastName = snapshot.value;
            self.user.lastName = newLastName;
            
            [self.tableView reloadData];
        } else if ([snapshot.key isEqualToString:@"profile_image"]) {
            NSString *newProfileImageString = snapshot.value;
            self.user.profileImage = newProfileImageString;
            
            [self.tableView reloadData];
        }
        
        self.initialLoad = NO;
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


#pragma mark - Remove all observers before logging out
-(void)logout
{
    for (Firebase *ref in self.childObservers) {
        [ref removeAllObservers];
    }
}

@end
