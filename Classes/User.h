//
//  User.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Group;

@interface User : NSObject

@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *profileImage;
@property (nonatomic) BOOL completedRegistration;
@property (nonatomic) NSMutableArray *groups;

- (void)addGroup: (Group *)group;
- (void)removeGroup:(Group *)group;

@end
