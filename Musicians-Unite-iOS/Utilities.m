//
//  Utilities.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/17/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "Utilities.h"
#import "SharedData.h"
#import "AppConstant.h"

#import "MessageThread.h"
#import "Group.h"
#import "Message.h"
#import "User.h"
#import "Task.h"
#import "Recording.h"


@interface Utilities ()
@end


@implementation Utilities

+(void)toggleEyeball:(id) sender
{
    [sender isSelected] ? [sender setImage:[UIImage imageNamed:@"eye_inactive"] forState:UIControlStateNormal] : [sender setImage:[UIImage imageNamed:@"eye_active"] forState:UIControlStateSelected];
    [sender setSelected:![sender isSelected]];
}

// Adapted from http://stackoverflow.com/questions/7123667/is-there-any-way-to-make-a-text-field-entry-must-be-email-in-xcode
+ (BOOL)validateEmail:(NSString *)emailStr {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailStr];
}

+(NSString *)encodeImageToBase64:(UIImage *) image
{
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

+ (UIImage *)decodeBase64ToImage:(NSString *)strEncodeData
{
    NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}

+(void)removeEmptyTempUsers:(NSString *) userID withRef:(Firebase *) ref
{
    [[ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups", userID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            
            [[ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", userID]] removeValue];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


+(void)removeEmptyGroups:(NSString *) groupID withRef:(Firebase *) ref
{
    [[ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            
            [[ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                
                NSDictionary *groupData = snapshot.value;
                
                if (![groupData[@"message_threads"] isEqual:[NSNull null]]) {
                    
                    for (NSString *messageThreadID in [groupData[@"message_threads"] allKeys]) {
                        
                        [[ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@", messageThreadID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                            
                            NSDictionary *messageThreadData = snapshot.value;
                            
                            if (![messageThreadData[@"messages"] isEqual:[NSNull null]]) {
                                
                                for (NSString *messageID in [messageThreadData[@"messages"] allKeys]) {
                                    
                                    [[ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", messageID]] removeValue];
                                    
                                }
                            }
                            
                            [[ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@", messageThreadID]] removeValue];
                            
                        }];
                    }
                }
                
                if (![groupData[@"tasks"] isEqual:[NSNull null]])
                {
                    for (NSString *taskID in [groupData[@"tasks"] allKeys]) {
                        
                        [[ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", taskID]] removeValue];
                        
                    }
                }
                
                if (![groupData[@"recordings"] isEqual:[NSNull null]])
                {
                    for (NSString *recordingID in [groupData[@"recordings"] allKeys]) {
                        
                        [[ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", recordingID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                            
                            NSDictionary *recordingData = snapshot.value;
                            
                            if ([recordingData[@"creator"] isEqualToString:groupID])
                            {
                                [[ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", snapshot.key]] removeValue];
                            }
                            else
                            {
                                [[ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", snapshot.key]] updateChildValues:@{@"owner":recordingData[@"creator"]}];
                                [[ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", snapshot.key]] removeValue];
                            }
                            
                        }];
                        
                    }
                }
                
                [[ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]] removeValue];
                
            }];
            
        }
        
    } withCancelBlock:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
    }];
}


+(void)redToastMessage:(NSString *)message
{
    NSDictionary *options = @{
                              kCRToastTextKey : message,
                              kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                              kCRToastBackgroundColorKey : [UIColor redColor],
                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                              kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                              kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                              kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                              };
    
    [CRToastManager showNotificationWithOptions:options
                                completionBlock:^{
                                }];
}

+(void)greenToastMessage:(NSString *)message
{
    NSDictionary *options = @{
                              kCRToastTextKey : message,
                              kCRToastTextColorKey: [UIColor blackColor],
                              kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                              kCRToastBackgroundColorKey : [UIColor greenColor],
                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                              kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                              kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                              kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                              };
    
    [CRToastManager showNotificationWithOptions:options
                                completionBlock:^{
                                }];
}

@end


