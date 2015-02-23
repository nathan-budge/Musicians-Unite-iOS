//
//  MessageThread.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "MessageThread.h"

#import "User.h"
#import "Message.h"

@implementation MessageThread

- (id)init
{
    if (self = [super init]) {
        self.members = [[NSMutableArray alloc] init];
        self.messages = [[NSMutableArray alloc] init];
        return self;
    }
    return nil;
}


- (void)addMember: (User *)member
{
    [self.members addObject:member];
}

-(void)removeMember:(User *)member
{
    [self.members removeObject:member];
}

- (void)addMessage: (Message *)message
{
    [self.messages addObject:message];
}

-(void)removeMessage:(Message *)message
{
    [self.messages removeObject:message];
}

@end
