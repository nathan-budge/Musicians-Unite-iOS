//
//  GroupsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "UIViewController+ECSlidingViewController.h"
#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "GroupsTableViewController.h"
#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"


@interface GroupsTableViewController ()

//Firebase references
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userGroupRef;
@property (nonatomic) Firebase *groupRef;

//Array of user's groups
@property (nonatomic) NSMutableArray *groups;

//Pan gesture for navigation drawer
@property (nonatomic, strong) UIPanGestureRecognizer *dynamicTransitionPanGesture;

@property (nonatomic) NSString *selectedGroupID;

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



#pragma mark - View Handling

- (void)viewDidLoad {
    [super viewDidLoad];

    //Set up navigation drawer
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    [self updateGroups];
    
}

#pragma mark - Firebase observer for user groups

- (void)updateGroups
{
    self.userGroupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups", self.ref.authData.uid]];
    
    //Check if group was added to user's groups (and load initial groups)
    [self.userGroupRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        
        self.groupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]];
        
        [self.groupRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            NSMutableDictionary *newGroup = [[NSMutableDictionary alloc] init];
            [newGroup setObject:snapshot.value forKey:@"groupInfo"];
            [newGroup setObject:groupID forKey:@"groupID"];
            
            [self.groups addObject:newGroup];
            [self.tableView reloadData];
            
        }];
        
        //Create observer for changes to the group
        [self.groupRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
            NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
            
            NSUInteger index = [self.groups indexOfObject:[group objectAtIndex:0]];
            
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                
                NSMutableDictionary *updatedGroup = [[NSMutableDictionary alloc] init];
                [updatedGroup setObject:snapshot.value forKey:@"groupInfo"];
                [updatedGroup setObject:snapshot.key forKey:@"groupID"];
                
                [self.groups replaceObjectAtIndex:index withObject:updatedGroup];
                [self.tableView reloadData];
                
            }];
        }];
    }];
    
    
    //Observer for the removal of the current user from a group
    [self.userGroupRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", snapshot.key];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        [self.groups removeObject:[group objectAtIndex:0]];
        [self.tableView reloadData];
        
    }];
}


#pragma mark - Navigation Drawer

- (IBAction)actionDrawerToggle:(id)sender {
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showGroupTabs"]) {
        GroupTabBarController *destViewController = segue.destinationViewController;
        destViewController.groupID = self.selectedGroupID;
    } else if ([segue.identifier isEqualToString:@"newGroup"]) {
        GroupDetailViewController *destViewController = segue.destinationViewController;
        destViewController.groupID = @"";
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
    
    NSDictionary *group = [self.groups objectAtIndex:indexPath.row];
    cell.textLabel.text = group[@"groupInfo"][@"name"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *group = [self.groups objectAtIndex:indexPath.row];
    
    self.selectedGroupID = group[@"groupID"];
    
    [self performSegueWithIdentifier:@"showGroupTabs" sender:nil];
}

@end
