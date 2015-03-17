//
//  SharedData.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/28/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface SharedData : NSObject

@property (nonatomic, retain) NSMutableArray *childObservers;
@property (nonatomic) NSMutableArray *users;
@property (nonatomic, retain) NSMutableArray *groups;
@property (nonatomic) dispatch_group_t downloadGroup;


+ (SharedData *)sharedInstance;

- (void) addChildObserver:(Firebase *)childObserver;
- (void) addUser:(User *)user;
- (void) removeUser:(User *)user;

@end
