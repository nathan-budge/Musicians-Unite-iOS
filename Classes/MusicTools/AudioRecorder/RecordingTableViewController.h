//
//  RecordingTableViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/3/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Recording;
@class User;
@class Group;

@interface RecordingTableViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) Recording *recording;
@property (nonatomic) User *user;
@property (nonatomic) Group *group;

@end
