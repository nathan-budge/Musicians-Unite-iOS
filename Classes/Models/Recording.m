//
//  Recording.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "SharedData.h"
#import "AppConstant.h"

#import "Recording.h"
#import "Group.h"


@interface Recording ()

@property (weak, nonatomic) SharedData *sharedData;

@property (nonatomic) Group *group;

@end


@implementation Recording

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

- (Recording *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (Recording *)initWithRef: (Firebase *)recordingRef
{
    if (self = [super init])
    {
        self.recordingRef = recordingRef;
        
        [self.sharedData addChildObserver:self.recordingRef];
        
        [self loadRecordingData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}

- (Recording *)initWithRef: (Firebase *)recordingRef andGroup:(Group *)group
{
    if (self = [super init])
    {
        self.recordingRef = recordingRef;
        
        self.group = group;
        
        [self.sharedData addChildObserver:self.recordingRef];
        
        [self loadRecordingData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}


//*****************************************************************************/
#pragma mark - Load recording data
//*****************************************************************************/

- (void) loadRecordingData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.recordingRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *recordingData = snapshot.value;
        
        self.recordingID = snapshot.key;
        self.name = recordingData[@"name"];
        self.data = [[NSData alloc] initWithBase64EncodedString:recordingData[@"data"] options:0];
        self.ownerID = recordingData[@"owner"];
        
        if (self.group)
        {
            NSArray *newRecordingData = @[self.group, self];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewGroupAudioRecordingNotification object:newRecordingData];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewUserAudioRecordingNotification object:self];
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
    [self.recordingRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"name"])
        {
            self.name = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Recording Data Updated" object:self];
        }
        else if ([snapshot.key isEqualToString:@"owner"])
        {
            self.ownerID = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Recording Data Updated" object:self];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

@end
