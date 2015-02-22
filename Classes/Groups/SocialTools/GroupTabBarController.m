//
//  GroupTabBarController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/20/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "GroupTabBarController.h"
#import "GroupDetailViewController.h"


@implementation GroupTabBarController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *viewControllers = self.viewControllers;
    
    GroupDetailViewController *newGroupViewController = [viewControllers objectAtIndex:1];
    newGroupViewController.group = self.group;
}

@end
