//
//  User.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Group;
@class Firebase;

@interface User : NSObject

@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *email;
@property (nonatomic) UIImage *profileImage;
@property (nonatomic) BOOL completedRegistration;
@property (nonatomic) BOOL selected;
@property (nonatomic) NSMutableArray *groups;
@property (nonatomic) NSMutableArray *tasks;
@property (nonatomic) NSMutableArray *recordings;

//Firebase References
@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *userRef;
@property (nonatomic) Firebase *userGroupsRef;
@property (nonatomic) Firebase *userTasksRef;
@property (nonatomic) Firebase *userRecordingsRef;

//Constructor
- (User *)initWithRef: (Firebase *)userRef;
- (User *)initWithRef: (Firebase *)userRef andGroup: (Group *)group;


@end
