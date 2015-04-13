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

#import "MessageThread.h"
#import "Message.h"
#import "User.h"
#import "Group.h"


@interface MessageThread ()

//Firebase references
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *messageThreadRef;
@property (nonatomic) Firebase *threadMembersRef;
@property (nonatomic) Firebase *threadMessagesRef;

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
    if (self = [super init]) {
        self.messageThreadRef = messageThreadRef;
        self.threadMembersRef = [self.messageThreadRef childByAppendingPath:@"members"];
        self.threadMessagesRef = [self.messageThreadRef childByAppendingPath:@"messages"];
        
        [self.sharedData addChildObserver:self.messageThreadRef];
        [self.sharedData addChildObserver:self.threadMembersRef];
        [self.sharedData addChildObserver:self.threadMessagesRef];
        
        self.group = group;
        
        [self loadMessageThreadData];
        [self attachListenerForAddedMembers];
        [self attachListenerForAddedMessages];
        
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"New Thread" object:self];
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

-(void)attachListenerForAddedMembers
{
    [self.threadMembersRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *memberID = snapshot.key;
        
        if (![memberID isEqualToString:self.ref.authData.uid]) {
            
            dispatch_group_enter(self.sharedData.downloadGroup);
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", memberID];
            NSArray *member= [self.group.members filteredArrayUsingPredicate:predicate];
            
            //TOOD: Fix error where user no longer belongs to a group
            
            User *aMember = [member objectAtIndex:0];
            
            [self addMember:aMember];
            
            dispatch_group_leave(self.sharedData.downloadGroup);
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

-(void)attachListenerForAddedMessages
{
    [self.threadMessagesRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *messageID = snapshot.key;
        
        Firebase *messageRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", messageID]];
        Message *newMessage = [[Message alloc] initWithRef:messageRef andGroup:self.group];
        [self addMessage:newMessage];
        
        //Double check notifications
        [[NSNotificationCenter defaultCenter] postNotificationName:@"New Message" object:self];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

//TODO: Remove Messages Listener


//*****************************************************************************/
#pragma mark - Array handling
//*****************************************************************************/

- (void)addMember: (User *)member
{
    [self.members addObject:member];
}

-(void)removeMember:(User *)member
{
    [self.members removeObject:member];
}

- (void)addMessage: (Message *)message
{
    [self.messages addObject:message];
}

-(void)removeMessage:(Message *)message
{
    [self.messages removeObject:message];
}

@end
