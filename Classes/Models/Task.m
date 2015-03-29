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

@interface Task ()

@property (nonatomic) Firebase *taskRef;

@property (weak, nonatomic) SharedData *sharedData;

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
        
        if ([taskData[@"completed"] isEqual:@YES]) {
            self.completed = YES;
            
        } else {
            self.completed = NO;
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Data Updated" object:self];
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Data Updated" object:self];
            
        } else if ([snapshot.key isEqualToString:@"tempo"]) {
            self.tempo = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Data Updated" object:self];
            
        } else if ([snapshot.key isEqualToString:@"notes"]) {
            self.notes = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Data Updated" object:self];
            
        } else if ([snapshot.key isEqualToString:@"completed"]) {
            
            if ([snapshot.value isEqual:@YES]) {
                self.completed = YES;
                
            } else {
                self.completed = NO;
                
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Task Data Updated" object:self];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
    }];
}

@end
