//
//  AppDelegate.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/13/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "AppDelegate.h"
#import <Firebase/Firebase.h>

#import "AppConstant.h"

#import "User.h"

@interface AppDelegate ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) UIApplication *application;
@property (nonatomic) User *user;

@end

@implementation AppDelegate

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:
                                @"Main" bundle:[NSBundle mainBundle]];
    
    UIViewController *rootViewController = [[UIViewController alloc] init];
    
    NSDictionary *userInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    
    if(apsInfo) {
        //there is some pending push notification, so do something
        //in your case, show the desired viewController in this if block
    }
    
    if (self.ref.authData) {
        rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SlidingViewController"];
    } else {
        rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];
    }
    
    self.window.rootViewController = rootViewController;
    
    [self.window makeKeyAndVisible];
    
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Remote Notifications"
                                               object:nil];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    self.application = application;

    return YES;
}

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Remote Notifications"])
    {
        [self.application registerForRemoteNotifications];
        self.user = (User *)notification.object;
    }
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSLog(@"My token is: %@", deviceToken);
    
    NSString *tokenString = [deviceToken description];
    tokenString = [tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *deviceID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    NSLog(@"My device id is: %@", deviceID);
    
    Firebase *devicesRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"devices/%@", deviceID]];
    Firebase *userDevicesRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/devices", self.user.userID]];
    
    NSDictionary *updatedDeviceValues = @{
                                          @"device_type":@"iOS",
                                          @"device_token":tokenString,
                                          };
    
    NSDictionary *updatedUserValues = @{
                                        deviceID:@TRUE,
                                        };
    
    [devicesRef updateChildValues:updatedDeviceValues];
    [userDevicesRef updateChildValues:updatedUserValues];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
