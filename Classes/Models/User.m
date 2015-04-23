//
//  User.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "User.h"
#import "Group.h"
#import "Task.h"
#import "Recording.h"
#import "MessageThread.h"
#import "Message.h"

@interface User ()

@property (weak, nonatomic) SharedData *sharedData;

@property (nonatomic) Group *group;

@end

@implementation User

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

- (User *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (User *)initWithRef: (Firebase *)userRef
{
    if (self = [super init]) {
        self.userRef = userRef;
        
        [self.sharedData addChildObserver:self.userRef];
        
        [self loadUserData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}

- (User *)initWithRef: (Firebase *)userRef andGroup: (Group *)group
{
    if (self = [super init]) {
        self.userRef = userRef;
        
        [self.sharedData addChildObserver:self.userRef];
        
        self.group = group;
        
        [self loadUserData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}


//*****************************************************************************/
# pragma mark - Load user data
//*****************************************************************************/

- (void)loadUserData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.userRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *memberData = snapshot.value;
        
        self.userID = snapshot.key;
        self.email = memberData[@"email"];
        
        if ([memberData[@"completed_registration"] isEqual:@YES])
        {
            self.completedRegistration = YES;
            self.firstName = memberData[@"first_name"];
            self.lastName = memberData[@"last_name"];
            self.profileImage = [Utilities decodeBase64ToImage:memberData[@"profile_image"]];
        }
        else
        {
            self.completedRegistration = NO;
        }
        
        if ([self.userID isEqualToString:self.ref.authData.uid])
        {
            self.userGroupsRef = [self.userRef childByAppendingPath:@"groups"];
            self.userTasksRef = [self.userRef childByAppendingPath:@"tasks"];
            self.userRecordingsRef = [self.userRef childByAppendingPath:@"recordings"];
            
            [self.sharedData addChildObserver:self.userGroupsRef];
            [self.sharedData addChildObserver:self.userTasksRef];
            [self.sharedData addChildObserver:self.userRecordingsRef];
            
            [self.userGroupsRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                
                if ([snapshot.value isEqual:[NSNull null]]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"No Groups" object:self];
                }
                
            } withCancelBlock:^(NSError *error) {
                NSLog(@"%@", error.description);
            }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Remote Notifications" object:self];
            
            [self attachListenerForAddedGroups];
            [self attachListenerForRemovedGroups];
            [self attachListenerForAddedTasks];
            [self attachListenerForRemovedTasks];
            [self attachListenerForAddedRecordings];
            [self attachListenerForRemovedRecordings];
        }
        
        if (self.group)
        {
            NSArray *newMemberData = @[self.group, self];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"New Group Member" object:newMemberData];
        }
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

- (void)attachListenerForChanges
{
    [self.userRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"first_name"])
        {
            self.firstName = snapshot.value;
        }
        else if ([snapshot.key isEqualToString:@"last_name"])
        {
            self.lastName = snapshot.value;
        }
        else if ([snapshot.key isEqualToString:@"profile_image"])
        {
            self.profileImage = [Utilities decodeBase64ToImage:snapshot.value];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForAddedGroups
{
    [self.userGroupsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *newGroupID = snapshot.key;
        
        Firebase *groupRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", newGroupID]];
        
        Group *newGroup = [[Group alloc] initWithRef:groupRef];
        
        [self addGroup:newGroup];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForRemovedGroups
{
    [self.userGroupsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", snapshot.key];
        NSArray *group = [self.groups filteredArrayUsingPredicate:predicate];
        
        if (group.count > 0)
        {
            Group *removedGroup = [group objectAtIndex:0];
            
            /*Remove Firebase listeners for group*/
            
            //Task observers
            for (Task *task in removedGroup.tasks) {
                [task.taskRef removeAllObservers];
            }
            
            //Recording observers
            for (Recording *recording in removedGroup.recordings) {
                [recording.recordingRef removeAllObservers];
            }
            
            
            //Group observers
            [removedGroup.groupRef removeAllObservers];
            [removedGroup.groupMembersRef removeAllObservers];
            [removedGroup.groupMessageThreadsRef removeAllObservers];
            [removedGroup.groupTasksRef removeAllObservers];
            [removedGroup.groupRecordingsRef removeAllObservers];
            
            
            //Remove groups with no more members left (currently a utilities method)
            
            [self removeGroup:removedGroup];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Group Removed" object:removedGroup];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForAddedTasks
{
    [self.userTasksRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
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
    [self.userTasksRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.taskID=%@", snapshot.key];
        NSArray *task = [self.tasks filteredArrayUsingPredicate:predicate];
        
        if (task.count > 0)
        {
            Task *removedTask = [task objectAtIndex:0];
            [self removeTask:removedTask];
            
            NSArray *removedTaskData = @[self, removedTask];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Removed" object:removedTaskData];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

- (void)attachListenerForAddedRecordings
{
    [self.userRecordingsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
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
    [self.userRecordingsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
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
#pragma mark - Array handling
//*****************************************************************************/

- (void)addGroup: (Group *)group
{
    [self.groups addObject:group];
}

- (void)removeGroup:(Group *)group
{
    [self.groups removeObject:group];
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
