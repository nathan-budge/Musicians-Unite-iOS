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

@interface User ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;
@property (nonatomic) Firebase *userGroupsRef;
@property (nonatomic) Firebase *userTasksRef;
@property (nonatomic) Firebase *userRecordingsRef;

@property (weak, nonatomic) SharedData *sharedData;

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
        
        if ([memberData[@"completed_registration"] isEqual:@YES]) {
            self.completedRegistration = YES;
            self.firstName = memberData[@"first_name"];
            self.lastName = memberData[@"last_name"];
            self.profileImage = [Utilities decodeBase64ToImage:memberData[@"profile_image"]];
        }else {
            self.completedRegistration = NO;
        }
        
        if ([self.userID isEqualToString:self.ref.authData.uid]) {
            
            self.userTasksRef = [self.userRef childByAppendingPath:@"tasks"];
            self.userRecordingsRef = [self.userRef childByAppendingPath:@"recordings"];
            
            [self.sharedData addChildObserver:self.userTasksRef];
            [self.sharedData addChildObserver:self.userRecordingsRef];
            
            [self attachListenerForAddedTasks];
            [self attachListenerForRemovedTasks];
            [self attachListenerForAddedRecordings];
            [self attachListenerForRemovedRecordings];
        }
        
        [self.sharedData addUser:self];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
    }];
}


//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

- (void)attachListenerForChanges
{
    
    [self.userRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"first_name"]) {
            self.firstName = snapshot.value;
            
        } else if ([snapshot.key isEqualToString:@"last_name"]) {
            self.lastName = snapshot.value;
            
        } else if ([snapshot.key isEqualToString:@"profile_image"]) {
            self.profileImage = [Utilities decodeBase64ToImage:snapshot.value];
            
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
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
        NSLog(@"ERROR: %@", error);
    }];
}

- (void)attachListenerForRemovedTasks
{
    [self.userTasksRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.taskID=%@", snapshot.key];
        NSArray *task = [self.tasks filteredArrayUsingPredicate:predicate];
        
        if (task.count > 0) {
            Task *removedTask = [task objectAtIndex:0];
            [self removeTask:removedTask];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
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
        NSLog(@"ERROR: %@", error);
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
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
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
