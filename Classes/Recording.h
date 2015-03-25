//
//  Recording.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Firebase;

@interface Recording : NSObject

@property (nonatomic) NSString *recordingID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSData *data;

- (Recording *)initWithRef: (Firebase *)recordingRef;

@end
