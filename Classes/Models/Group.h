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


//Constructors
- (Group *)initWithName: (NSString *)name andProfileImageString:(NSString *)profileImageString;
- (Group *)initWithRef: (Firebase *)groupRef;


//Array methods
//- (void)addMember: (User *)member;
//- (void)removeMember:(User *)member;

//- (void)addMessageThread: (MessageThread *)messageThread;
//- (void)removeMessageThread:(MessageThread *)messageThread;

@end
