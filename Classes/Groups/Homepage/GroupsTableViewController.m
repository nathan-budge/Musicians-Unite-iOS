//
//  GroupsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"

#import "GroupsTableViewController.h"
#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"

#import "User.h"
#import "Group.h"


@interface GroupsTableViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;

@property (nonatomic, weak) SharedData *sharedData;

@property (nonatomic) Group *selectedGroup;
@property (nonatomic) NSMutableArray *groups;

@property (nonatomic, strong) UIPanGestureRecognizer *dynamicTransitionPanGesture;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonMenu;

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (assign) BOOL initialLoad;

@end


@implementation GroupsTableViewController

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


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupDataUpdatedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kGroupRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNoGroupsNotification
                                               object:nil];
    
    [self.sharedData addNotificationCenterObserver:self];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *activityButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    UIBarButtonItem *newGroupButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionNewGroup)];
    self.navigationItem.rightBarButtonItems = @[newGroupButton, activityButton];
    
    [self loadUser];
}


//*****************************************************************************/
#pragma mark - Load User
//*****************************************************************************/

-(void)loadUser
{
    Firebase *connectedRef = [self.ref childByAppendingPath:kNetworkConnectionNode];
    [self.sharedData addChildObserver:connectedRef];
    
    [connectedRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if([snapshot.value boolValue])
        {
            [SVProgressHUD dismiss];
            
            if (!self.sharedData.user)
            {
                self.initialLoad = YES;
                
                [self.activityIndicator startAnimating];
                
                self.userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kUsersFirebaseNode, self.ref.authData.uid]];
                self.sharedData.user = [[User alloc] initWithRef:self.userRef];
            }
        }
        else
        {
            [SVProgressHUD showErrorWithStatus:kNetworkError maskType:SVProgressHUDMaskTypeBlack];
        }
    }];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kGroupDataUpdatedNotification])
    {
        [self.tableView reloadData];
    }
    else if ([[notification name] isEqualToString:kNewGroupNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            [self.groups addObject:notification.object];
            [self.tableView reloadData];
            
            if (self.initialLoad)
            {
                if (self.groups.count == self.sharedData.user.groups.count)
                {
                    [self.activityIndicator stopAnimating];
                    self.initialLoad = NO;
                }
            }
            else
            {
                NSDictionary *options = @{
                                          kCRToastTextKey : kNewGroupSuccessMessage,
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
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kGroupRemovedNotification])
    {
        [self.groups removeObject:notification.object];
        [self.tableView reloadData];
        
        NSDictionary *options = @{
                                  kCRToastTextKey : kGroupRemovedSuccessMessage,
                                  kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                  kCRToastBackgroundColorKey : [UIColor redColor],
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                  };
        
        [CRToastManager showNotificationWithOptions:options
                                    completionBlock:^{
                                    }];
    }
    else if ([[notification name] isEqualToString:kNoGroupsNotification])
    {
        [self.activityIndicator stopAnimating];
    }
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionDrawerToggle:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (void)actionNewGroup
{
    [self performSegueWithIdentifier:kNewGroupSegueIdentifier sender:nil];
}


//*****************************************************************************/
#pragma mark - Prepare for segue
//*****************************************************************************/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kGroupTabsSegueIdentifier])
    {
        GroupTabBarController *destViewController = segue.destinationViewController;
        destViewController.group = self.selectedGroup;
    }
    else if ([segue.identifier isEqualToString:kNewGroupSegueIdentifier])
    {
        GroupDetailViewController *destViewController = segue.destinationViewController;
        destViewController.group = nil;
    }
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
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGroupCellIdentifier];
    
    Group *group = [self.groups objectAtIndex:indexPath.row];
    
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
    
    [self performSegueWithIdentifier:kGroupTabsSegueIdentifier sender:nil];
}


@end
