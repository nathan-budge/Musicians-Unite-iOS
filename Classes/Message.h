//
//  Message.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Message : NSObject

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *text;
@property (nonatomic) UIImage *attachment;
@property (nonatomic) UIImage *profileImage;

@end
