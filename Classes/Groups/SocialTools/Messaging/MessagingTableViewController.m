//
//  MessagingTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "SharedData.h"
#import "AppConstant.h"

#import "MessagingTableViewController.h"
#import "NewMessageTableViewController.h"
#import "MessageViewController.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"
#import "Message.h"


@interface MessagingTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) MessageThread *selectedMessageThread;
@property (nonatomic) NSMutableArray *messageThreads;

@property (nonatomic) SharedData *sharedData;

@end


@implementation MessagingTableViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Thread"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Thread Removed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Message"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Message Removed"
                                               object:nil];
    
    self.messageThreads = [NSMutableArray arrayWithArray:self.group.messageThreads];
    
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.title = @"Messages";
    self.tabBarController.navigationItem.rightBarButtonItems = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionNewGroup)];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

-(void)actionNewGroup
{
    [self performSegueWithIdentifier:@"newMessage" sender:self];
}


//*****************************************************************************/
#pragma mark - UIActionSheet Methods
//*****************************************************************************/

- (void)deleteThread:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateBegan) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Delete"
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
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/message_threads/%@", self.group.groupID, removedMessageThread.messageThreadID]] removeValue];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@", removedMessageThread.messageThreadID]] removeValue];
    
    for (Message *removedMessage in removedMessageThread.messages) {
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@/messages/%@", removedMessageThread.messageThreadID, removedMessage.messageID]] removeValue];
        [[self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", removedMessage.messageID]] removeValue];
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"New Thread"])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            [self.messageThreads addObject:notification.object];
            [self.tableView reloadData];
        });
    }
    else if ([[notification name] isEqualToString:@"Thread Removed"])
    {
        MessageThread *removedMessageThread = notification.object;
        [self.messageThreads removeObject:removedMessageThread];
        [self.tableView reloadData];
    }
    else if ([[notification name] isEqualToString:@"New Message"] || [[notification name] isEqualToString:@"Message Removed"])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
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
    return self.messageThreads.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteThread:)];
    [cell addGestureRecognizer:longPress];
    
    MessageThread *messageThread = [self.messageThreads objectAtIndex:indexPath.row];
   
    messageThread.title = [self getThreadTitle:messageThread];
    cell.textLabel.text = messageThread.title;
    
    Message *mostRecentMessage = [messageThread.messages lastObject];
    
    if (mostRecentMessage)
    {
        if ([mostRecentMessage.sender isEqual:self.user.userID])
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"You: %@", mostRecentMessage.text];
        }
        else
        {
            User *sender = mostRecentMessage.sender;
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
    [self performSegueWithIdentifier:@"viewThread" sender:nil];
}


//*****************************************************************************/
#pragma mark - Helper Methods
//*****************************************************************************/

-(NSString *)getThreadTitle: (MessageThread *)messageThread
{
    NSMutableString *title = [[NSMutableString alloc] init];
    
    if ([messageThread.members count] == 1)
    {
        User *member = [messageThread.members objectAtIndex:0];
        [title appendString:[NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName]];
    }
    else if ([messageThread.members count] == 2)
    {
        for (int i = 0; i < [messageThread.members count]; i++) {
            
            User *member = [messageThread.members objectAtIndex:i];
            
            if (i == ([messageThread.members count] - 1)) {
                [title appendString:[NSString stringWithFormat:@"and %@ %@", member.firstName, member.lastName]];
                
            } else {
                [title appendString:[NSString stringWithFormat:@"%@ %@ ", member.firstName, member.lastName]];
                
            }
        }
    }
    else
    {
        for (int i = 0; i < [messageThread.members count]; i++) {
            
            User *member = [messageThread.members objectAtIndex:i];
            
            if (i == ([messageThread.members count] - 1)) {
                [title appendString:[NSString stringWithFormat:@"and %@ %@", member.firstName, member.lastName]];
                
            } else {
                [title appendString:[NSString stringWithFormat:@"%@ %@, ", member.firstName, member.lastName]];
                
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
    if ([segue.identifier isEqualToString:@"newMessage"])
    {
        NewMessageTableViewController *destViewController = segue.destinationViewController;
        destViewController.group = self.group;
        destViewController.user = self.user;
    }
    else if ([segue.identifier isEqualToString:@"viewThread"])
    {
        MessageViewController *destViewController = segue.destinationViewController;
        destViewController.messageThread = self.selectedMessageThread;
        destViewController.user = self.user;
    }
}

@end
