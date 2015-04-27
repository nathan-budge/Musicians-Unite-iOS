//
//  MessageTableViewCell.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from https://github.com/slackhq/SlackTextViewController/blob/master/Examples/Messenger/Messenger-Shared/MessageTableViewCell.h
//

#import <UIKit/UIKit.h>

#define kAvatarSize 30.0
#define kMinimumHeight 60.0

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UIImageView *attachmentView;

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic, readonly) BOOL needsPlaceholder;
@property (nonatomic) BOOL usedForMessage;

@end
