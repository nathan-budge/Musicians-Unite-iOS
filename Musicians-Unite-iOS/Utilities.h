//
//  Utilities.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/17/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Firebase;
@class MessageThread;
@class Group;

@interface Utilities : NSObject

+(void)toggleEyeball:(id) sender;
+(BOOL)validateEmail:(NSString *)emailStr;

+(void)removeEmptyGroups:(NSString *) groupID withRef:(Firebase *) ref;
+(void)removeEmptyTempUsers:(NSString *) userID withRef:(Firebase *) ref;

+(NSString *)encodeImageToBase64:(UIImage *) image;
+(UIImage *)decodeBase64ToImage:(NSString *)strEncodeData;

+(void)redToastMessage:(NSString *)message;
+(void)greenToastMessage:(NSString *)message;

@end

