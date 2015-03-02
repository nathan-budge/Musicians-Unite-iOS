//
//  GroupsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "GroupsTableViewController.h"
#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"
#import "NavigationDrawerViewController.h"

#import "User.h"
#import "Group.h"
#import "MessageThread.h"
#import "Message.h"


@interface GroupsTableViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;
@property (nonatomic) Firebase *userGroupsRef;

@property (nonatomic) SharedData *sharedData;

@property (nonatomic) Group *selectedGroup;
@property (nonatomic) NSMutableArray *groups;

@property (nonatomic, strong) UIPanGestureRecognizer *dynamicTransitionPanGesture;

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

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


-(NSMutableArray *)groups
{
    if (!_groups) {
        _groups = [[NSMutableArray alloc] init];
    }
    
    return _groups;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Data Loaded"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Finished Loading"
                                               object:nil];
    
    self.userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", self.ref.authData.uid]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", self.ref.authData.uid];
    NSArray *user = [self.sharedData.users filteredArrayUsingPredicate:predicate];
    
    if (user.count > 0) {
        self.user = [user objectAtIndex:0];
        NSLog(@"%@ already exists", self.user.email);
    } else {
        self.user = [[User alloc] initWithRef:self.userRef];
    }
    
    [SVProgressHUD showWithStatus:@"Loading" maskType:SVProgressHUDMaskTypeBlack];
    
    [self loadUser];
    [self loadGroups];
}


#pragma mark - Load User

-(void)loadUser
{
    NavigationDrawerViewController *navigationDrawerViewController = (NavigationDrawerViewController *)self.slidingViewController.underLeftViewController;
    navigationDrawerViewController.user = self.user;
}


#pragma mark - Load Groups

- (void)loadGroups
{
    self.userGroupsRef = [self.userRef childByAppendingPath:@"groups"];
    [self.sharedData addChildObserver:self.userGroupsRef];
    
    [self attachListenerForAddedGroupsToUser]; 
    [self attachListenerForRemovedGroupsToUser];
}

-(void)attachListenerForAddedGroupsToUser
{
    [self.userGroupsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        
        Firebase *groupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]];
        
        Group *newGroup = [[Group alloc] initWithRef:groupRef];
        
        [self.groups addObject:newGroup];
        [self.user addGroup:newGroup];
        
        NSNotification *myNotification =
        [NSNotification notificationWithName:@"Finished Loading" object:nil];
        
        [[NSNotificationQueue defaultQueue]
         enqueueNotification:myNotification
         postingStyle:NSPostWhenIdle];
        
    }];
}

- (void)attachListenerForRemovedGroupsToUser
{
    [self.userGroupsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *groupID = snapshot.key;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", groupID];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        [self.groups removeObject:[group objectAtIndex:0]];
        [self.user removeGroup:[group objectAtIndex:0]];
        [self.tableView reloadData];
        
    }];
}


#pragma mark - Notification Center

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Data Loaded"]) {
        [self.tableView reloadData];
        
    } else if ([[notification name] isEqualToString:@"Finished Loading"]) {
        [SVProgressHUD showSuccessWithStatus:@"Data Loaded" maskType:SVProgressHUDMaskTypeBlack];
        
    }
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
        destViewController.user = self.user;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell"];
    
    Group *group = [self.groups objectAtIndex:indexPath.row];
    
    //Get subviews
    UIImageView *profileImageView = (UIImageView *)[cell viewWithTag:1];
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
    profileImageView.layer.masksToBounds = YES;
    [profileImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [profileImageView.layer setBorderWidth: 1.0];
    
    UILabel *groupName = (UILabel *)[cell viewWithTag:2];
    
    //Set subviews
    profileImageView.image = group.profileImage;
    groupName.text = group.name;
    
    return cell;    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedGroup = [self.groups objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"showGroupTabs" sender:nil];
}


@end
