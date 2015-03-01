//
//  NavigationDrawerViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "SharedData.h"

#import "NavigationDrawerViewController.h"
#import "UserSettingsViewController.h"
#import "GroupsTableViewController.h"

#import "User.h"
#import "Group.h"


@interface NavigationDrawerViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic, strong) UINavigationController *transitionsNavigationController;

@property (weak, nonatomic) IBOutlet UIButton *buttonHome;
@property (weak, nonatomic) IBOutlet UIButton *buttonUserSettings;

@end


@implementation NavigationDrawerViewController

#pragma mark - Lazy instantiation

- (Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.transitionsNavigationController = (UINavigationController *)self.slidingViewController.topViewController;
}


#pragma mark - Buttons

- (IBAction)actionHome:(id)sender
{
    self.slidingViewController.topViewController = self.transitionsNavigationController;
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionUserSettings:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UserSettingsNavigationController"];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionLogout:(id)sender
{
    [SVProgressHUD showWithStatus:@"Logging out..." maskType:SVProgressHUDMaskTypeBlack];
    
    SharedData *childObservers = [SharedData sharedInstance];
    
    for (Firebase *ref in childObservers.childObservers) {
        [ref removeAllObservers];
    }
    
    [self.ref unauth];

    [self performSegueWithIdentifier:@"Logout" sender:sender];
    [SVProgressHUD dismiss];
}

@end
