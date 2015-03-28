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
#import "Utilities.h"
#import "AppConstant.h"


@interface Utilities ()
@end


@implementation Utilities

+(void)toggleEyeball:(id) sender
{
    [sender isSelected] ? [sender setImage:[UIImage imageNamed:@"eye_inactive"] forState:UIControlStateNormal] : [sender setImage:[UIImage imageNamed:@"eye_active"] forState:UIControlStateSelected];
    [sender setSelected:![sender isSelected]];
}

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
        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
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
                
                [[ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]] removeValue];
                
            }];
            
        }
        
    } withCancelBlock:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
    }];
}

@end


