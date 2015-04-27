//
//  Group.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class User;
@class MessageThread;
@class Firebase;

@interface Group : NSObject

@property (nonatomic) NSString *groupID;
@property (nonatomic) NSString *name;
@property (nonatomic) UIImage *profileImage;
@property (nonatomic) NSMutableArray *members;
@property (nonatomic) NSMutableArray *messageThreads;
@property (nonatomic) NSMutableArray *tasks;
@property (nonatomic) NSMutableArray *recordings;

//Firebase references
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *groupRef;
@property (nonatomic) Firebase *groupMembersRef;
@property (nonatomic) Firebase *groupMessageThreadsRef;
@property (nonatomic) Firebase *groupTasksRef;
@property (nonatomic) Firebase *groupRecordingsRef;

//Constructors
- (Group *)initWithName: (NSString *)name andProfileImageString:(NSString *)profileImageString;
- (Group *)initWithRef: (Firebase *)groupRef;

//Array Method
- (void)addMessageThread: (MessageThread *)messageThread;
- (void)removeMessageThread:(MessageThread *)messageThread;

@end
