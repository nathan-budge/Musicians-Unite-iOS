//
//  Task.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Firebase;

@interface Task : NSObject

@property (nonatomic) NSString *taskID;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *tempo;
@property (nonatomic) NSString *notes;
@property (nonatomic) BOOL completed;

- (Task *)initWithRef: (Firebase *)taskRef;

@end
