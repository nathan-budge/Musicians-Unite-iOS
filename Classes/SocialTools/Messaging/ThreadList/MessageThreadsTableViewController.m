//
//  MessageThreadsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "CRToast.h"

#import "SharedData.h"
#import "AppConstant.h"
#import "Utilities.h"

#import "MessageThreadsTableViewController.h"
#import "NewMessageThreadTableViewController.h"
#import "MessageViewController.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"
#import "Message.h"


@interface MessageThreadsTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (nonatomic) MessageThread *selectedMessageThread;
@property (nonatomic) NSMutableArray *messageThreads;

@end


@implementation MessageThreadsTableViewController

//*****************************************************************************/
#pragma mark - Lazy instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}

-(NSMutableArray *)messageThreads
{
    if (!_messageThreads) {
        _messageThreads = [[NSMutableArray alloc] init];
    }
    return _messageThreads;
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
    
    self.messageThreads = [NSMutableArray arrayWithArray:self.group.messageThreads];
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageThreadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kMessageThreadRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kMessageRemovedNotification
                                               object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionNewGroup:(id)sender
{
    [self performSegueWithIdentifier:kNewMessageSegueIdentifier sender:self];
}


//*****************************************************************************/
#pragma mark - UIActionSheet Methods
//*****************************************************************************/

- (void)deleteThread:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateBegan)
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:kCancelButtonTitle
                                                   destructiveButtonTitle:kDeleteButtonTitle
                                                        otherButtonTitles: nil];
        
        
        //Adapted from http://stackoverflow.com/questions/7144592/getting-cell-indexpath-on-swipe-gesture-uitableview
        CGPoint location = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        
        actionSheet.tag = indexPath.row;
        [actionSheet showInView:gesture.view];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self removeMessageThread:actionSheet.tag];
            break;
        default:
            break;
    }
}

- (void)removeMessageThread:(NSInteger)row
{
    MessageThread *removedMessageThread = [self.messageThreads objectAtIndex:row];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kMessageThreadsFirebaseNode, removedMessageThread.messageThreadID]] removeValue];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kMessageThreadsFirebaseNode, removedMessageThread.messageThreadID]] removeValue];
    
    for (Message *removedMessage in removedMessageThread.messages) {
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kMessageThreadsFirebaseNode, removedMessageThread.messageThreadID, kMessagesFirebaseNode, removedMessage.messageID]] removeValue];
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kMessagesFirebaseNode, removedMessage.messageID]] removeValue];
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
                MessageThread *newThread = [newThreadData objectAtIndex:1];
                [self.messageThreads addObject:newThread];
                [self.tableView reloadData];
                
                [Utilities greenToastMessage:kNewMessageThreadSuccessMessage];
            }

        });
    }
    else if ([[notification name] isEqualToString:kMessageThreadRemovedNotification])
    {
        NSArray *removedThreadData = notification.object;
        if ([[removedThreadData objectAtIndex:0] isEqual:self.group])
        {
            MessageThread *removedMessageThread = [removedThreadData objectAtIndex:1];
            [self.messageThreads removeObject:removedMessageThread];
            [self.tableView reloadData];
            
            [Utilities redToastMessage:kMessageThreadRemovedSuccessMessage];
        }
    }
    else if ([[notification name] isEqualToString:kNewMessageNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            NSArray *newMessageData = notification.object;
            if ([[newMessageData objectAtIndex:2] isEqual:self.group])
            {
                MessageThread *updatedMessageThread = [newMessageData objectAtIndex:0];
                [self.messageThreads removeObject:updatedMessageThread];
                [self.messageThreads insertObject:updatedMessageThread atIndex:0];
                
                [self.group.messageThreads removeObject:updatedMessageThread];
                [self.group.messageThreads insertObject:updatedMessageThread atIndex:0];
                
                [self.tableView reloadData];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kMessageRemovedNotification])
    {
        NSArray *newMessageData = notification.object;
        if ([[newMessageData objectAtIndex:2] isEqual:self.group])
        {
            [self.tableView reloadData];
        }
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
    return self.messageThreads.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageThreadCellIdentifier];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteThread:)];
    [cell addGestureRecognizer:longPress];
    
    MessageThread *messageThread = [self.messageThreads objectAtIndex:indexPath.row];
   
    messageThread.title = [self getThreadTitle:messageThread];
    cell.textLabel.text = messageThread.title;
    
    Message *mostRecentMessage = [messageThread.messages lastObject];
   
    if (mostRecentMessage)
    {        
        if ([mostRecentMessage.senderID isEqual:self.sharedData.user.userID])
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"You: %@", mostRecentMessage.text];
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", mostRecentMessage.senderID];
            NSArray *member = [self.group.members filteredArrayUsingPredicate:predicate];
            
            User *sender = [member objectAtIndex:0];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@: %@", sender.firstName, sender.lastName, mostRecentMessage.text];
        }
        
    }
    else
    {
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMessageThread = [self.group.messageThreads objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:kThreadDetailSegueIdentifier sender:nil];
}


//*****************************************************************************/
#pragma mark - Helper Methods
//*****************************************************************************/

-(NSString *)getThreadTitle: (MessageThread *)messageThread
{
    NSMutableString *title = [[NSMutableString alloc] init];
    
    if ([messageThread.members count] == 1)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", [messageThread.members objectAtIndex:0]];
        NSArray *member = [self.group.members filteredArrayUsingPredicate:predicate];
        
        User *threadMember = [member objectAtIndex:0];
        
        [title appendString:[NSString stringWithFormat:@"%@", threadMember.firstName]];
    }
    else if ([messageThread.members count] == 2)
    {
        for (int i = 0; i < [messageThread.members count]; i++) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", [messageThread.members objectAtIndex:i]];
            NSArray *member = [self.group.members filteredArrayUsingPredicate:predicate];
            
            User *threadMember = [member objectAtIndex:0];
            
            if (i == ([messageThread.members count] - 1))
            {
                [title appendString:[NSString stringWithFormat:@"and %@", threadMember.firstName]];
            }
            else
            {
                [title appendString:[NSString stringWithFormat:@"%@ ", threadMember.firstName]];
            }
        }
    }
    else
    {
        for (int i = 0; i < [messageThread.members count]; i++) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", [messageThread.members objectAtIndex:i]];
            NSArray *member = [self.group.members filteredArrayUsingPredicate:predicate];
            
            User *threadMember = [member objectAtIndex:0];
            
            if (i == ([messageThread.members count] - 1))
            {
                [title appendString:[NSString stringWithFormat:@"and %@", threadMember.firstName]];
            }
            else
            {
                [title appendString:[NSString stringWithFormat:@"%@, ", threadMember.firstName]];
            }
        }
    }
    
    return title;
}


//*****************************************************************************/
#pragma mark - Prepare for Segue
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kNewMessageSegueIdentifier])
    {
        NewMessageThreadTableViewController *destViewController = segue.destinationViewController;
        destViewController.group = self.group;
        destViewController.hidesBottomBarWhenPushed = YES;
    }
    else if ([segue.identifier isEqualToString:kThreadDetailSegueIdentifier])
    {
        MessageViewController *destViewController = segue.destinationViewController;
        destViewController.messageThread = self.selectedMessageThread;
        destViewController.group = self.group;
        destViewController.hidesBottomBarWhenPushed = YES;
    }
    
}

@end
