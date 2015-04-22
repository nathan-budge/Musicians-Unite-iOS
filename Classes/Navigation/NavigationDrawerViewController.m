//
//  NavigationDrawerViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"

#import "NavigationDrawerViewController.h"

#import "User.h"
#import "Group.h"


@interface NavigationDrawerViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic, strong) UINavigationController *transitionsNavigationController;

@property (weak, nonatomic) IBOutlet UIButton *buttonHome;
@property (weak, nonatomic) IBOutlet UIButton *buttonUserSettings;
@property (weak, nonatomic) IBOutlet UIButton *buttonMusicTools;
@property (weak, nonatomic) IBOutlet UIButton *buttonPracticeList;

@end


@implementation NavigationDrawerViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

- (Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.transitionsNavigationController = (UINavigationController *)self.slidingViewController.topViewController;
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionHome:(id)sender
{
    [self.transitionsNavigationController popToRootViewControllerAnimated:NO];
    self.slidingViewController.topViewController = self.transitionsNavigationController;
    [self.slidingViewController resetTopViewAnimated:YES];
}

-(IBAction)actionMusicTools:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMusicToolsNavigationController];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionPracticeList:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kPracticeListNavigationController];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionUserSettings:(id)sender
{
    self.slidingViewController.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kUserSettingsNavigationController];
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)actionLogout:(id)sender
{
    [SVProgressHUD showWithStatus:kLoggingOutProgressMessage maskType:SVProgressHUDMaskTypeBlack];
    
    SharedData *sharedData = [SharedData sharedInstance];
    
    for (Firebase *ref in sharedData.childObservers){
        [ref removeAllObservers];
    }
    
    for (id controller in sharedData.notificationCenterObservers) {
        [[NSNotificationCenter defaultCenter] removeObserver:controller];
    }
    
    [self.ref unauth];
    
    sharedData.user = nil;

    [SVProgressHUD dismiss];
    [self performSegueWithIdentifier:kLogoutSegueIdentifier sender:sender];
    
    NSDictionary *options = @{
                              kCRToastTextKey : kLoggedOutSuccessMessage,
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

@end
