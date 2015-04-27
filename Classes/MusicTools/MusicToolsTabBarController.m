//
//  MusicToolsTabBarController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "AppConstant.h"

#import "MusicToolsTabBarController.h"
#import "MetronomeViewController.h"
#import "DronesTableViewController.h"
#import "TunerViewController.h"

@interface MusicToolsTabBarController ()

@end

@implementation MusicToolsTabBarController

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    
    MetronomeViewController *metronomeViewController = [self.viewControllers objectAtIndex:0];
    if (self.tempo)
    {
        metronomeViewController.tempo = self.tempo;
    }    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    MetronomeViewController *metronomeViewController = [self.viewControllers objectAtIndex:0];
    [metronomeViewController stop];
    
    TunerViewController *tunerViewController = [self.viewControllers objectAtIndex:1];
    [tunerViewController beginInterruption];
    
    UINavigationController *dronesNavigationController = [self.viewControllers objectAtIndex:2];
    DronesTableViewController *dronesTableViewController = [dronesNavigationController.viewControllers objectAtIndex:0];
    [dronesTableViewController stop];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionDrawerToggle:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

@end
