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


+(void)removeEmptyGroups:(NSString *) groupID withRef:(Firebase *) ref
{
    //Check if a group has any members left
    [[ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/members", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            
            [[ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@", groupID]] removeValue];
            
            //Remove group's messages
            [[ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (![snapshot.value isEqual:[NSNull null]]) {
                    [[ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", groupID]] removeValue];
                }
            }];
            
            //Remove group's recordings
            [[ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (![snapshot.value isEqual:[NSNull null]]) {
                    [[ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", groupID]] removeValue];
                }
            }];
            
            //Remove groups's todo items
            [[ref childByAppendingPath:[NSString stringWithFormat:@"todo/%@", groupID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (![snapshot.value isEqual:[NSNull null]]) {
                    [[ref childByAppendingPath:[NSString stringWithFormat:@"todo/%@", groupID]] removeValue];
                }
            }];
        }
        
    } withCancelBlock:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
    }];
}

+(void)removeEmptyTempUsers:(NSString *) userID withRef:(Firebase *) ref
{
    //Check if a group has any members left
    [[ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/groups", userID]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            
            [[ref childByAppendingPath:[NSString stringWithFormat:@"users/%@", userID]] removeValue];
        }
        
    } withCancelBlock:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.description maskType:SVProgressHUDMaskTypeBlack];
    }];
}



@end


