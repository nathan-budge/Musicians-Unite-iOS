//
//  UserSettingsViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@interface UserSettingsViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic) User *user;

@end
