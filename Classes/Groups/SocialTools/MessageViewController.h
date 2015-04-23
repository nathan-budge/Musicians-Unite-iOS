//
//  MessageViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from https://github.com/slackhq/SlackTextViewController/blob/master/Examples/Messenger/Messenger-Shared/MessageViewController.h
//

#import "SLKTextViewController.h"

@class MessageThread;
@class Group;

@interface MessageViewController : SLKTextViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic) MessageThread *messageThread;
@property (nonatomic) Group *group;

@end
