//
//  Message.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "Message.h"
#import "User.h"
#import "Group.h"
#import "MessageThread.h"


@interface Message ()

@property (weak, nonatomic) SharedData *sharedData;

@property (nonatomic) Group *group;

@property (nonatomic) MessageThread *thread;

@end


@implementation Message

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

- (Message *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (Message *)initWithRef: (Firebase *)messageRef andGroup:(Group *)group andThread:(MessageThread *)thread
{
    if (self = [super init]) {
        self.messageRef = messageRef;
        
        self.group = group;
        self.thread = thread;
        
        [self loadMessageData];
        
        return self;
    }
    return nil;
}


//*****************************************************************************/
#pragma mark - Load message data
//*****************************************************************************/

- (void)loadMessageData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.messageRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *messageData = snapshot.value;
        
        self.messageID = snapshot.key;
        self.text = messageData[kMessageTextFirebaseField];
        self.senderID = messageData[kMessageSenderFirebaseField];
        
        NSArray *newMessageData = @[self.thread, self, self.group];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageNotification object:newMessageData];
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

@end
