//
//  NewMessageTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "NewMessageTableViewController.h"
#import "MessageViewController.h"
#import "MessagingTableViewController.h"

#import "Utilities.h"
#import "AppConstant.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"


@interface NewMessageTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) NSMutableArray *registeredMembers;

@end


@implementation NewMessageTableViewController

#pragma mark - Lazy instantiation

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


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (User *member in self.group.members) {
        if (member.completedRegistration) {
            member.selected = NO;
            [self.registeredMembers addObject:member];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Thread Loaded"
                                               object:nil];
}


#pragma mark - Notification Center

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Thread Loaded"]) {
        [SVProgressHUD showSuccessWithStatus:@"Thread Created" maskType:SVProgressHUDMaskTypeBlack];
        [self.navigationController popViewControllerAnimated:YES];
        
        
    }
}


#pragma mark - Buttons

- (IBAction)actionCreateChat:(id)sender
{
    NSMutableArray *newThreadMembers = [[NSMutableArray alloc] init];
    for (User *member in self.registeredMembers) {
        if (member.selected) {
            [newThreadMembers addObject:member];
            
        }
    }
    
    BOOL matchingGroup = NO;
    for (MessageThread *messageThread in self.group.messageThreads) {
        
        if (messageThread.members.count == newThreadMembers.count) {
            
            for (User *member in newThreadMembers) {
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", member.userID];
                NSArray *user = [messageThread.members filteredArrayUsingPredicate:predicate];
                
                if (user.count > 0) {
                    matchingGroup = YES;
                } else {
                    matchingGroup = NO;
        
                }
            
            }
        }
        
        if (matchingGroup) {
            break;
        }
    }
    
    if (matchingGroup) {
        [SVProgressHUD showErrorWithStatus:@"Thread already exists" maskType:SVProgressHUDMaskTypeBlack];
        
    } else if (newThreadMembers.count == 0){
        [SVProgressHUD showErrorWithStatus:@"No members selected" maskType:SVProgressHUDMaskTypeBlack];
        
    } else {
        Firebase* newMessageThread = [[self.ref childByAppendingPath:@"message_threads"] childByAutoId];
        
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/message_threads", self.group.groupID]] updateChildValues:@{newMessageThread.key:@YES}];
        
        for (User *member in newThreadMembers) {
            [[newMessageThread childByAppendingPath:@"members"] updateChildValues:@{member.userID:@YES}];
        }
        
        [[newMessageThread childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
        
        //[self performSegueWithIdentifier:@"viewNewThread" sender:nil];
        
        [SVProgressHUD showWithStatus:@"Creating Thread" maskType:SVProgressHUDMaskTypeBlack];
    }
}


#pragma mark - Prepare for Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return [self.registeredMembers count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.registeredMembers.count > 0) {
        return @"Select Members";
    }
    
    return @"No Registered Members";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    
    User *member = [self.registeredMembers objectAtIndex:indexPath.row];
    
    UIImageView *profileImageView = (UIImageView *)[cell viewWithTag:1];
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2;
    profileImageView.layer.masksToBounds = YES;
    [profileImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [profileImageView.layer setBorderWidth: 1.0];
    
    UILabel *userName = (UILabel *)[cell viewWithTag:2];
    
    profileImageView.image = member.profileImage;
    
    userName.text = [NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName];
    
    if (member.selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
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
