//
//  SharedData.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/28/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "SharedData.h"

#import "User.h"
#import "Group.h"

@interface SharedData ()

@end

@implementation SharedData

#pragma mark - Instantiation

+ (SharedData *)sharedInstance
{
    static SharedData *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (SharedData *)init
{
    if (self = [super init]) {
        self.childObservers = [[NSMutableArray alloc] init];
        self.users = [[NSMutableArray alloc] init];
        self.downloadGroup = dispatch_group_create();
        return self;
    }
    return nil;
}

#pragma mark - Array handling

- (void) addChildObserver:(Firebase *)childObserver
{
    [self.childObservers addObject:childObserver];
}


- (void) addUser:(User *)user
{
    [self.users addObject:user];
    dispatch_group_leave(self.downloadGroup);
}

- (void) removeUser:(User *)user
{
    [self.users removeObject:user];
}

- (void) addGroup:(Group *)group
{
    [self.groups addObject:group];
}


@end
