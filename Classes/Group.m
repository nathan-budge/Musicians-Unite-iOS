//
//  Group.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "Group.h"
#import "User.h"
#import "MessageThread.h"


@implementation Group

- (id)init
{
    if (self = [super init]) {
        self.members = [[NSMutableArray alloc] init];
        self.messageThreads = [[NSMutableArray alloc] init];
        return self;
    }
    return nil;
}


- (id)initWithName: (NSString *)name andProfileImageString:(NSString *)profileImageString
{
    if (self = [super init]) {
        self.members = [[NSMutableArray alloc] init];
        self.messageThreads = [[NSMutableArray alloc] init];
        self.name = name;
        self.profileImage = profileImageString;
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

- (void)addMessageThread: (MessageThread *)messageThread
{
    [self.messageThreads addObject:messageThread];
}

-(void)removeMessageThread:(MessageThread *)messageThread
{
    [self.messageThreads removeObject:messageThread];
}

@end
