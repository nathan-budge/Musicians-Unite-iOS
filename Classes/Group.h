//
//  Group.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface Group : NSObject

@property (nonatomic) NSString *groupID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *profileImage;
@property (nonatomic) NSMutableArray *members;

- (id)initWithName: (NSString *)name andProfileImageString:(NSString *)profileImageString;
- (void)addMember: (User *)member;
- (void)removeMember:(User *)member;

@end
