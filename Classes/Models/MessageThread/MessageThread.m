//
//  MessageThread.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "MessageThread.h"
#import "Message.h"
#import "User.h"
#import "Group.h"


@interface MessageThread ()

//Shared data 
@property (weak, nonatomic) SharedData *sharedData;

//Group object
@property (nonatomic) Group *group;

@end


@implementation MessageThread

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

-(NSMutableArray *)members
{
    if (!_members) {
        _members = [[NSMutableArray alloc] init];
    }
    return _members;
}

-(NSMutableArray *)messages
{
    if (!_messages) {
        _messages = [[NSMutableArray alloc] init];
    }
    return _messages;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


//*****************************************************************************/
#pragma mark - Instantiation
//*****************************************************************************/

- (MessageThread *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}


- (MessageThread *)initWithRef: (Firebase *)messageThreadRef andGroup: (Group *)group
{
    if (self = [super init])
    {
        self.messageThreadRef = messageThreadRef;
        self.threadMembersRef = [self.messageThreadRef childByAppendingPath:@"members"];
        self.threadMessagesRef = [self.messageThreadRef childByAppendingPath:@"messages"];
        
        [self.sharedData addChildObserver:self.messageThreadRef];
        [self.sharedData addChildObserver:self.threadMembersRef];
        [self.sharedData addChildObserver:self.threadMessagesRef];
        
        self.group = group;
        
        [self loadMessageThreadData];
        [self attachListenerForAddedMembers];
        [self attachListenerForRemovedMembers];
        [self attachListenerForAddedMessages];
        [self attachListenerForRemovedMessages];
        
        return self;
    }
    
    return nil;
}


//*****************************************************************************/
#pragma mark - Load message thread data
//*****************************************************************************/

- (void)loadMessageThreadData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.messageThreadRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.messageThreadID = snapshot.key;
        
         NSArray *newThreadData = @[self.group, self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"New Thread" object:newThreadData];
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

- (void)attachListenerForAddedMembers
{
    [self.threadMembersRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *memberID = snapshot.key;
        
        if (![memberID isEqualToString:self.sharedData.user.userID])
        {
            [self addMember:memberID];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

-(void)attachListenerForRemovedMembers
{
    [self.threadMembersRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *memberID = snapshot.key;
        
        NSString *userID;
        if ([self.members containsObject:memberID])
        {
            userID = memberID;
        }
        else
        {
            userID = self.sharedData.user.userID;
        }
        
        //Delete necessary threads and messages
        if (self.members.count == 1)
        {
            [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/message_threads/%@", self.group.groupID, self.messageThreadID]] removeValue];
            [self.messageThreadRef removeValue];
            
            for (Message *message in self.messages) {
                [[self.threadMessagesRef childByAppendingPath:message.messageID] removeValue];
                [[self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", message.messageID]] removeValue];
            }
        }
        else
        {
            for (Message *message in self.messages) {
                
                if ([message.senderID isEqualToString:userID])
                {
                    [[self.threadMessagesRef childByAppendingPath:message.messageID] removeValue];
                    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", message.messageID]] removeValue];
                }
            }
        }
        
        if ([self.members containsObject:memberID])
        {
            [self removeMember:memberID];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


-(void)attachListenerForAddedMessages
{
    [self.threadMessagesRef observeEventType:FEventTypeChildAdded andPreviousSiblingKeyWithBlock:^(FDataSnapshot *snapshot, NSString *prevKey) {
        
        NSString *messageID = snapshot.key;
        
        Firebase *messageRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", messageID]];
        Message *newMessage = [[Message alloc] initWithRef:messageRef andGroup:self.group andThread:self];
        [self addMessage:newMessage];
        
    } withCancelBlock:^(NSError *error) {
         NSLog(@"ERROR: %@", error.description);
    }];
}

-(void)attachListenerForRemovedMessages
{
    [self.threadMessagesRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *messageID = snapshot.key;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.messageID=%@", messageID];
        NSArray *message = [self.messages filteredArrayUsingPredicate:predicate];
        
        if (message.count > 0)
        {
            Message *removedMessage = [message objectAtIndex:0];
            [self removeMessage:removedMessage];
            
            NSArray *removedMessageData = @[self, removedMessage, self.group];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Message Removed" object:removedMessageData];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Array handling
//*****************************************************************************/

-(void)addMember: (NSString *)memberID
{
    [self.members addObject:memberID];
}

-(void)removeMember:(NSString *)memberID
{
    [self.members removeObject:memberID];
}

-(void)addMessage: (Message *)message
{
    [self.messages addObject:message];
}

-(void)removeMessage:(Message *)message
{
    [self.messages removeObject:message];
}

@end
