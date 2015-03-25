//
//  MusicToolsTabBarController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "UIViewController+ECSlidingViewController.h"

#import "MusicToolsTabBarController.h"

@interface MusicToolsTabBarController ()

@end

@implementation MusicToolsTabBarController

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionDrawerToggle:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

@end
