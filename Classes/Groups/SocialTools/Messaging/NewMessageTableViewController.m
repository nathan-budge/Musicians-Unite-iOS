//
//  NewMessageTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "Utilities.h"
#import "AppConstant.h"
#import "SharedData.h"

#import "NewMessageTableViewController.h"
#import "MessageViewController.h"
#import "MessagingTableViewController.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"


@interface NewMessageTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (nonatomic) NSString *threadID; //Keep track of new thread ID

@property (nonatomic) NSMutableArray *registeredMembers;

@end


@implementation NewMessageTableViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if(!_ref){
        _ref =[[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}

-(NSMutableArray *)registeredMembers
{
    if (!_registeredMembers) {
        _registeredMembers = [[NSMutableArray alloc] init];
    }
    return _registeredMembers;
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
    
    for (User *member in self.group.members) {
        
        if (member.completedRegistration)
        {
            member.selected = NO;
            [self.registeredMembers addObject:member];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageThreadNotification
                                               object:nil];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionCreateChat:(id)sender
{
    NSMutableArray *newThreadMembers = [[NSMutableArray alloc] init];
    
    for (User *member in self.registeredMembers) {
        
        if (member.selected)
        {
            [newThreadMembers addObject:member];
        }
        
    }
    
    BOOL matchingGroup = NO;
    for (MessageThread *messageThread in self.group.messageThreads) {
        
        if (messageThread.members.count == newThreadMembers.count)
        {
            for (User *member in newThreadMembers) {
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", member.userID];
                NSArray *user = [messageThread.members filteredArrayUsingPredicate:predicate];
                
                if (user.count > 0)
                {
                    matchingGroup = YES;
                }
                else
                {
                    matchingGroup = NO;
                }
            
            }
        }
        
        if (matchingGroup)
        {
            break;
        }
    }
    
    if (matchingGroup)
    {
        [SVProgressHUD showErrorWithStatus:kThreadAlreadyExistsError maskType:SVProgressHUDMaskTypeBlack];
    }
    else if (newThreadMembers.count == 0)
    {
        [SVProgressHUD showErrorWithStatus:kNoThreadMembersSelectedError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase* newMessageThread = [[self.ref childByAppendingPath:kMessageThreadsFirebaseNode] childByAutoId];
        
        self.threadID = newMessageThread.key;
        
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kMessageThreadsFirebaseNode]] updateChildValues:@{newMessageThread.key:@YES}];
        
        for (User *member in newThreadMembers) {
            [[newMessageThread childByAppendingPath:kMembersFirebaseNode] updateChildValues:@{member.userID:@YES}];
        }
        
        [[newMessageThread childByAppendingPath:kMembersFirebaseNode] updateChildValues:@{self.sharedData.user.userID:@YES}];
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewMessageThreadNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            NSArray *newThreadData = notification.object;
            if ([[newThreadData objectAtIndex:0] isEqual:self.group])
            {
                MessageThread *newMessageThread = [newThreadData objectAtIndex:1];
                if ([newMessageThread.messageThreadID isEqualToString:self.threadID])
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            
        });
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
    return self.registeredMembers.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.registeredMembers.count > 0)
    {
        return kSelectMembersSectionHeader;
    }
    
    return kNoRegisterdMembersSectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserCellIdentifier];
    
    User *member = [self.registeredMembers objectAtIndex:indexPath.row];
    
    UIImageView *profileImageView = (UIImageView *)[cell viewWithTag:1];
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
    profileImageView.layer.masksToBounds = YES;
    [profileImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [profileImageView.layer setBorderWidth: 1.0];
    
    UILabel *userName = (UILabel *)[cell viewWithTag:2];
    
    profileImageView.image = member.profileImage;
    
    userName.text = [NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName];
    
    if (member.selected)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    User *selectedUser = [self.registeredMembers objectAtIndex:indexPath.row];
    selectedUser.selected = !selectedUser.selected;
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
