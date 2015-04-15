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
#import "Task.h"
#import "Recording.h"

@interface Group ()

//Firebase references
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *groupRef;
@property (nonatomic) Firebase *groupMembersRef;
@property (nonatomic) Firebase *groupMessageThreadsRef;
@property (nonatomic) Firebase *groupTasksRef;
@property (nonatomic) Firebase *groupRecordingsRef;

//Shared data singleton
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

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
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

-(NSMutableArray *)tasks
{
    if (!_tasks) {
        _tasks = [[NSMutableArray alloc] init];
    }
    return _tasks;
}

-(NSMutableArray *)recordings
{
    if (!_recordings) {
        _recordings = [[NSMutableArray alloc] init];
    }
    return _recordings;
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
        self.groupTasksRef = [self.groupRef childByAppendingPath:@"tasks"];
        self.groupRecordingsRef = [self.groupRef childByAppendingPath:@"recordings"];
        
        [self.sharedData addChildObserver:self.groupRef];
        [self.sharedData addChildObserver:self.groupMembersRef];
        [self.sharedData addChildObserver:self.groupMessageThreadsRef];
        [self.sharedData addChildObserver:self.groupTasksRef];
        [self.sharedData addChildObserver:self.groupRecordingsRef];
        
        [self loadGroupData];
        
        [self attachListenerForChanges];
        [self attachListenerForAddedMembers];
        [self attachListenerForRemovedMembers];
        [self attachListenerForAddedMessageThreads];
        [self attachListenerForAddedTasks];
        [self attachListenerForRemovedTasks];
        [self attachListenerForAddedRecordings];
        [self attachListenerForRemovedRecordings];
        
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"New Group" object:self];
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

- (void)attachListenerForChanges
{
    [self.groupRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"name"]) {
            
            self.name = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Group Data Updated" object:self];
            
        } else if ([snapshot.key isEqualToString:@"profile_image"]) {
            
            self.profileImage = [Utilities decodeBase64ToImage:snapshot.value];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Group Data Updated" object:self];
            
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForAddedMembers
{
    [self.groupMembersRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *newMemberID = snapshot.key;
        
        if (![newMemberID isEqualToString:self.ref.authData.uid])
        {
            Firebase *userRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", newMemberID]];
            User *newUser = [[User alloc] initWithRef:userRef];
            [self addMember:newUser];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

- (void)attachListenerForRemovedMembers
{
    [self.groupMembersRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", snapshot.key];
        NSArray *member = [self.members filteredArrayUsingPredicate:predicate];
        
        if (member.count > 0)
        {
            User *removedMember = [member objectAtIndex:0];
            [self removeMember:removedMember];
            
            //TODO: Notification, User Removed?
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

- (void)attachListenerForAddedMessageThreads
{
    [self.groupMessageThreadsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *newMessageThreadID = snapshot.key;
        
        Firebase *messageThreadRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@", newMessageThreadID]];
        
        [messageThreadRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
           
            NSDictionary *messageThreadData = snapshot.value;
            
            if ([[messageThreadData[@"members"] allKeys] containsObject:self.ref.authData.uid])
            {
                MessageThread *newMessageThread = [[MessageThread alloc] initWithRef:messageThreadRef andGroup:self];
                [self addMessageThread:newMessageThread];
            }
            
        } withCancelBlock:^(NSError *error) {
            NSLog(@"ERROR: %@", error.description);
        }];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForAddedTasks
{
    [self.groupTasksRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *newTaskID = snapshot.key;
        
        Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", newTaskID]];
        
        Task *newTask = [[Task alloc] initWithRef:taskRef];
        
        [self addTask:newTask];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForRemovedTasks
{
    [self.groupTasksRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.taskID=%@", snapshot.key];
        NSArray *task = [self.tasks filteredArrayUsingPredicate:predicate];
        
        if (task.count > 0) {
            Task *removedTask = [task objectAtIndex:0];
            [self removeTask:removedTask];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Removed" object:removedTask];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForAddedRecordings
{
    [self.groupRecordingsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *newRecordingID = snapshot.key;
        
        Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", newRecordingID]];
        
        Recording *newRecording = [[Recording alloc] initWithRef:recordingRef];
        
        [self addRecording:newRecording];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForRemovedRecordings
{
    [self.groupRecordingsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.recordingID=%@", snapshot.key];
        NSArray *recording = [self.recordings filteredArrayUsingPredicate:predicate];
        
        if (recording.count > 0) {
            Recording *removedRecording = [recording objectAtIndex:0];
            [self removeRecording:removedRecording];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Recording Removed" object:self];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Array Handling
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

- (void)addTask: (Task *)task
{
    [self.tasks addObject:task];
}

- (void)removeTask: (Task *)task
{
    [self.tasks removeObject:task];
}

- (void)addRecording: (Recording *)recording
{
    [self.recordings addObject:recording];
}

- (void)removeRecording: (Recording *)recording
{
    [self.recordings removeObject:recording];
}

@end
