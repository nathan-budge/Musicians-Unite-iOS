//
//  Utilities.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/17/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

@interface Utilities : NSObject

+(void)removeEmptyGroups:(NSString *) groupID withRef:(Firebase *) ref;
+(void)toggleEyeball:(id) sender;
+(BOOL)validateEmail:(NSString *)emailStr;

@end

