//
//  Recording.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "SharedData.h"

#import "Recording.h"

@interface Recording ()

@property (nonatomic) Firebase *recordingRef;

@property (weak, nonatomic) SharedData *sharedData;

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

- (Recording *)initWithRef: (Firebase *)recordingRef
{
    if (self = [super init]) {
        self.recordingRef = recordingRef;
        
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
        self.title = recordingData[@"title"];
        self.recording = [[NSData alloc] initWithBase64EncodedString:recordingData[@"recording"] options:0];
        
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
    [self.recordingRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"title"]) {
            self.title = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Recording Data Updated" object:self];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
    }];
}

@end
