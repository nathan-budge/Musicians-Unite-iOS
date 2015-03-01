//
//  Message.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "SharedData.h"

#import "Message.h"
#import "User.h"
#import "Group.h"


@interface Message ()

@property (nonatomic) Firebase *messageRef;

@property (nonatomic) SharedData *childObservers;

@end


@implementation Message

#pragma mark - Instantiation

- (Message *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (Message *)initWithRef: (Firebase *)messageRef
{
    if (self = [super init]) {
        self.messageRef = messageRef;
        
        self.childObservers = [SharedData sharedInstance];
        [self.childObservers addChildObserver:messageRef];
        
        [self loadMessageData];
        
        return self;
    }
    return nil;
}


#pragma mark - Load message data

- (void)loadMessageData
{
    [self.messageRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *messageData = snapshot.value;
        
        self.messageID = snapshot.key;
        self.text = messageData[@"text"];
        
        NSString *senderID = messageData[@"sender"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", senderID];
        NSArray *member= [self.childObservers.users filteredArrayUsingPredicate:predicate];
        User *aMember = [member objectAtIndex:0];
        
        self.sender = aMember;
        
    }];
}

@end
