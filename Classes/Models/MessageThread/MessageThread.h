//
//  MessageThread.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Message;
@class User;
@class Firebase;
@class Group;

@interface MessageThread : NSObject

@property (nonatomic) NSString *messageThreadID;
@property (nonatomic) NSMutableArray *members;
@property (nonatomic) NSMutableArray *messages;

@property (nonatomic) NSString *title;

//Firebase references
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *messageThreadRef;
@property (nonatomic) Firebase *threadMembersRef;
@property (nonatomic) Firebase *threadMessagesRef;

//Constructor
- (MessageThread *)initWithRef: (Firebase *)messageThreadRef andGroup: (Group *)group;

//Array mehtodds
-(void)addMessage: (Message *)message;
-(void)removeMessage:(Message *)message;

@end
