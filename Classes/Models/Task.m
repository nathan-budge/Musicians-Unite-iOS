//
//  Task.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "Task.h"
#import <Firebase/Firebase.h>

#import "SharedData.h"
#import "AppConstant.h"

#import "Group.h"

@interface Task ()

@property (weak, nonatomic) SharedData *sharedData;

@property (nonatomic) Group *group;

@end


@implementation Task

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

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

- (Task *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (Task *)initWithRef: (Firebase *)taskRef
{
    if (self = [super init]) {
        self.taskRef = taskRef;
        
        [self.sharedData addChildObserver:self.taskRef];
        
        [self loadTaskData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}

- (Task *)initWithRef: (Firebase *)taskRef andGroup:(Group *)group
{
    if (self = [super init]) {
        self.taskRef = taskRef;
        
        self.group = group;
        
        [self.sharedData addChildObserver:self.taskRef];
        
        [self loadTaskData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}


//*****************************************************************************/
#pragma mark - Load task data
//*****************************************************************************/

- (void) loadTaskData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.taskRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *taskData = snapshot.value;
        
        self.taskID = snapshot.key;
        self.title = taskData[@"title"];
        self.tempo = taskData[@"tempo"];
        self.notes = taskData[@"notes"];
        
        if ([taskData[@"completed"] isEqual:@YES])
        {
            self.completed = YES;
        }
        else
        {
            self.completed = NO;
        }
        
        if (self.group)
        {
            NSArray *newTaskData = @[self.group, self];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"New Group Task" object:newTaskData];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"New User Task" object:self];
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
    [self.taskRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"title"]) {
            self.title = snapshot.value;
            
            if (self.group)
            {
                NSArray *updatedTaskData = @[self.group, self];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupTaskDataUpdatedNotification object:updatedTaskData];
                
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserTaskDataUpdatedNotification object:self];
            }
            
        }
        else if ([snapshot.key isEqualToString:@"tempo"])
        {
            self.tempo = snapshot.value;
            
            if (self.group)
            {
                NSArray *updatedTaskData = @[self.group, self];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupTaskDataUpdatedNotification object:updatedTaskData];
                
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserTaskDataUpdatedNotification object:self];
            }
            
        }
        else if ([snapshot.key isEqualToString:@"notes"])
        {
            self.notes = snapshot.value;
            
            if (self.group)
            {
                NSArray *updatedTaskData = @[self.group, self];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupTaskDataUpdatedNotification object:updatedTaskData];
                
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserTaskDataUpdatedNotification object:self];
            }
            
        }
        else if ([snapshot.key isEqualToString:@"completed"])
        {
            if ([snapshot.value isEqual:@YES])
            {
                self.completed = YES;
                
                if (self.group)
                {
                    NSArray *completedTaskData = @[self.group, self];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupTaskCompletedNotification object:completedTaskData];
                    
                }
                else
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserTaskCompletedNotification object:self];
                }
            }
            else
            {
                self.completed = NO;
            }
            
            if (self.group)
            {
                NSArray *updatedTaskData = @[self.group, self];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupTaskDataUpdatedNotification object:updatedTaskData];
                
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserTaskDataUpdatedNotification object:self];
            }
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

@end
