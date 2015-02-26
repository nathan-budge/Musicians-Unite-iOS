//
//  MessageViewController.h
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "SLKTextViewController.h"

@class MessageThread;
@class User;

@interface MessageViewController : SLKTextViewController <UIActionSheetDelegate>

@property (nonatomic) MessageThread *messageThread;
@property (nonatomic) User *user;

@end
