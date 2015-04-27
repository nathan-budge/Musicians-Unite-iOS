//
//  GroupDetailTableViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/27/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;

@interface GroupDetailTableViewController : UITableViewController <UITextFieldDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>

@property (nonatomic) Group *group;

@end
