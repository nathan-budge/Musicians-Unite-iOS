//
//  Recording.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Firebase;
@class Group;

@interface Recording : NSObject

@property (nonatomic) NSString *recordingID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSData *data;
@property (nonatomic) NSString *ownerID;
@property (nonatomic) NSString *creatorID;

//Firebase reference
@property (nonatomic) Firebase *recordingRef;

//Constructor
- (Recording *)initWithRef: (Firebase *)recordingRef;
- (Recording *)initWithRef: (Firebase *)recordingRef andGroup:(Group *)group;

@end
