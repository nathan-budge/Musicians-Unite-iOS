//
//  Group.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class MessageThread;

@interface Group : NSObject

@property (nonatomic) NSString *groupID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *profileImage;
@property (nonatomic) NSMutableArray *members;
@property (nonatomic) NSMutableArray *messageThreads;

- (id)initWithName: (NSString *)name andProfileImageString:(NSString *)profileImageString;

- (void)addMember: (User *)member;
- (void)removeMember:(User *)member;

- (void)addMessageThread: (MessageThread *)messageThread;
- (void)removeMessageThread:(MessageThread *)messageThread;

@end
