//
//  NavigationDrawerViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Adapted from https://github.com/ECSlidingViewController/ECSlidingViewController/tree/master/Examples/TransitionFun
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "NavigationDrawerViewController.h"
#import "UIViewController+ECSlidingViewController.h"

@interface NavigationDrawerViewController ()
@property (nonatomic, strong) UINavigationController *transitionsNavigationController;
@end

@implementation NavigationDrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.transitionsNavigationController = (UINavigationController *)self.slidingViewController.topViewController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)actionHome:(id)sender {
    self.slidingViewController.topViewController = self.transitionsNavigationController;
    
    [self.slidingViewController resetTopViewAnimated:YES];
}



- (IBAction)actionUserSettings:(id)sender {
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UserSettingsNavigationController"];
    
    [self.slidingViewController resetTopViewAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
