//
//  MemberManagementViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"

@interface MemberManagementViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) Group *group;

@end
