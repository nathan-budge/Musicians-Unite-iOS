//
//  User.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "User.h"
#import "Group.h"

@implementation User

- (id)init
{
    if (self = [super init]) {
        self.groups = [[NSMutableArray alloc] init];
        return self;
    }
    return nil;
}

- (void)addGroup: (Group *)group
{
    [self.groups addObject:group];
}

-(void)removeGroup:(Group *)group
{
    [self.groups removeObject:group];
}

@end
