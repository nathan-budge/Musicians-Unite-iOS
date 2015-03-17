//
//  Group.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"

@interface Group ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *groupRef;
@property (nonatomic) Firebase *groupMembersRef;
@property (nonatomic) Firebase *groupMessageThreadsRef;

@property (weak, nonatomic) SharedData *sharedData;

@end


@implementation Group

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

-(NSMutableArray *)members
{
    if (!_members) {
        _members = [[NSMutableArray alloc] init];
    }
    return _members;
}

-(NSMutableArray *)messageThreads
{
    if(!_messageThreads){
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
#pragma mark - Instantiation
//*****************************************************************************/

- (Group *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (Group *)initWithName: (NSString *)name andProfileImageString:(NSString *)profileImageString
{
    if (self = [super init]) {
        self.name = name;
        self.profileImage = [Utilities decodeBase64ToImage:profileImageString];
        return self;
    }
    return nil;
}

- (Group *)initWithRef: (Firebase *)groupRef
{
    if (self = [super init]) {
        self.groupRef = groupRef;
        self.groupMembersRef = [self.groupRef childByAppendingPath:@"members"];
        self.groupMessageThreadsRef = [self.groupRef childByAppendingPath:@"message_threads"];
        
        [self.sharedData addChildObserver:self.groupRef];
        [self.sharedData addChildObserver:self.groupMembersRef];
        [self.sharedData addChildObserver:self.groupMessageThreadsRef];
        
        [self loadGroupData];
        
        [self attachListenerForAddedMembers];
        [self attachListenerForRemovedMembers];
        [self attachListenerForChanges];
        [self attachListenerForAddedMessageThreads];
        
        return self;
    }
    
    return nil;
}


//*****************************************************************************/
#pragma mark - Load group data
//*****************************************************************************/

- (void)loadGroupData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.groupRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *groupData = snapshot.value;
        
        self.groupID = snapshot.key;
        self.name = groupData[@"name"];
        self.profileImage = [Utilities decodeBase64ToImage:groupData[@"profile_image"]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Data Loaded" object:self];
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    }];
}

//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

- (void)attachListenerForAddedMembers
{
    [self.groupMembersRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *newMemberID = snapshot.key;
        
        if (![newMemberID isEqualToString:self.ref.authData.uid]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", newMemberID];
            NSArray *userArray = [self.sharedData.users filteredArrayUsingPredicate:predicate];
            
            if (userArray.count > 0) {
                User *aUser = [userArray objectAtIndex:0];
                [aUser addGroup:self];
                [self addMember:aUser];
                
                //NSLog(@"%@ already exists", aUser.email);
                
            } else {
                Firebase *userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", newMemberID]];
                
                User *newUser = [[User alloc] initWithRef:userRef];
                [newUser addGroup:self];
                [self addMember:newUser];
                
                //NSLog(@"User Created %@", userRef.key);
            }
            
        }
    }];
}

- (void)attachListenerForRemovedMembers
{
    [self.groupMembersRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", snapshot.key];
        NSArray *member = [self.members filteredArrayUsingPredicate:predicate];
        
        if (member.count > 0) {
            User *removedMember = [member objectAtIndex:0];
            [self removeMember:removedMember];
            
            [removedMember removeGroup:self];
            
            if (removedMember.groups.count == 0) {
                [self.sharedData removeUser:removedMember];
                NSLog(@"%lu", (unsigned long)self.sharedData.users.count);
            }
            
        }
        
    }];
}

- (void)attachListenerForChanges
{
    [self.groupRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"name"]) {
            
            self.name = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Data Loaded" object:self];
            
        } else if ([snapshot.key isEqualToString:@"profile_image"]) {
            
            self.profileImage = [Utilities decodeBase64ToImage:snapshot.value];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Data Loaded" object:self];
            
        }
    }];
}

-(void)attachListenerForAddedMessageThreads
{
    [self.groupMessageThreadsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {

        NSString *newMessageThreadID = snapshot.key;
        
        Firebase *messageThreadRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@", newMessageThreadID]];
        
        [messageThreadRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            NSDictionary *messageThreadData = snapshot.value;
            
            if ([[messageThreadData[@"members"] allKeys] containsObject:self.ref.authData.uid]) {
                
                MessageThread *newMessageThread = [[MessageThread alloc] initWithRef:messageThreadRef];
                
                [self addMessageThread:newMessageThread];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Thread Loaded" object:self];
            }
        }];
    }];
}


//*****************************************************************************/
#pragma mark - Array handling
//*****************************************************************************/

- (void)addMember: (User *)member
{
    [self.members addObject:member];
}

- (void)removeMember:(User *)member
{
    [self.members removeObject:member];
}

- (void)addMessageThread: (MessageThread *)messageThread
{
    [self.messageThreads addObject:messageThread];
}

- (void)removeMessageThread:(MessageThread *)messageThread
{
    [self.messageThreads removeObject:messageThread];
}

@end
