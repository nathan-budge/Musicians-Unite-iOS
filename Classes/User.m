//
//  User.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "User.h"
#import "Group.h"

@interface User ()

@property (nonatomic) Firebase *userRef;

@property (nonatomic) SharedData *sharedData;

@end

@implementation User

#pragma mark - Instantiation

- (User *)init
{
    if (self = [super init]) {
        self.groups = [[NSMutableArray alloc] init];
        return self;
    }
    return nil;
}

- (User *)initWithRef: (Firebase *)userRef
{
    if (self = [super init]) {
        self.groups = [[NSMutableArray alloc] init];
        self.userRef = userRef;
        
        self.sharedData = [SharedData sharedInstance];
        [self.sharedData addChildObserver:self.userRef];
        
        [self loadUserData];
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}


# pragma mark - Load user data

- (void)loadUserData
{
    [self.userRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *memberData = snapshot.value;
        
        self.userID = snapshot.key;
        self.email = memberData[@"email"];
        
        if ([memberData[@"completed_registration"] isEqual:@YES]) {
            self.completedRegistration = YES;
            self.firstName = memberData[@"first_name"];
            self.lastName = memberData[@"last_name"];
            self.profileImage = [Utilities decodeBase64ToImage:memberData[@"profile_image"]];
        }else {
            self.completedRegistration = NO;
        }
        
        [self.sharedData addUser:self];
        
    }];
}


#pragma mark - Firebase observers

- (void)attachListenerForChanges
{
    [self.userRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:@"first_name"]) {
            
            self.firstName = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Data Loaded" object:self];
            
        } else if ([snapshot.key isEqualToString:@"last_name"]) {

            self.lastName = snapshot.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Data Loaded" object:self];
            
        } else if ([snapshot.key isEqualToString:@"profile_image"]) {
            
            self.profileImage = [Utilities decodeBase64ToImage:snapshot.value];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Data Loaded" object:self];
        }
        
    }];
}


#pragma mark - Array handling

- (void)addGroup: (Group *)group
{
    [self.groups addObject:group];
}

-(void)removeGroup:(Group *)group
{
    [self.groups removeObject:group];
}

@end
