//
//  AppConstant.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#define FIREBASE_URL @"https://blazing-heat-4549.firebaseio.com"

//Naviation Controller Storyboard IDs
#define kMusicToolsNavigationController             @"MusicToolsNavigationController"
#define kPracticeListNavigationController           @"PracticeListNavigationController"
#define kUserSettingsNavigationController           @"UserSettingsNavigationController"

//Status Messages
#define kLoggingOutProgressMessage                  @"Logging out..."
#define kLoggingInProgressMessage                   @"Logging in..."
#define kRegisteringProgressMessage                 @"Registering..."
#define kDeletingAccountProgressMessage             @"Deleting account..."
#define kChangingPasswordProgressMessage            @"Changing password..."

//Segue Identifiers
#define kLogoutSegueIdentifier                      @"Logout"
#define kLoginToGroupSegueIdentifier                @"LoginToGroups"
#define kRegisterToGroupSegueIdentifier             @"RegisterToGroups"
#define kChangePasswordSegueIdentifier              @"changePassword"
#define kDeleteAccountSegueIdentifier               @"deleteAccount"
#define kNewGroupSegueIdentifier                    @"newGroup"
#define kGroupTabsSegueIdentifier                   @"showGroupTabs"

//Cell Identifiers
#define kGroupCellIdentifier                        @"GroupCell"

//Error Messages
#define kError                                      @"Error"
#define kInvalidEmailPasswordError                  @"Invalid email and/or password"
#define kInvalidEmailError                          @"Invalid Email"
#define kInvalidPasswordError                       @"Invalid Password"
#define kEmailTakenError                            @"Email is already taken"
#define kUserDoesNotExistError                      @"User does not exist"
#define kNetworkError                               @"Network Error"
#define kNoFirstNameError                           @"First name is required"
#define kNoCameraError                              @"Device has no camera"

//Success Messages
#define kResetPasswordSuccessMessage                @"Password reset email sent!"
#define kUserDataSavedSuccessMessage                @"User Saved!"
#define kAccountDeletedSuccessMessage               @"Account Deleted!"
#define kAccountCreatedSuccessMessage               @"Account Created!"
#define kPasswordChangedSuccessMessage              @"Password Changed!"
#define kNewGroupSuccessMessage                     @"New Group! :)"
#define kGroupRemovedSuccessMessage                 @"Group Removed!"
#define kLoggedOutSuccessMessage                    @"Logged Out!"
#define kLoggedInSuccessMessage                     @"Logged In!"

//Alert Messages
#define kForgotPasswordAlertMessage                 @"Please enter your email address"
#define kDeleteAccountAlertMessage                  @"Please enter your password"

//Button Titles
#define kConfirmButtonTitle                         @"OK"
#define kCancelButtonTitle                          @"Cancel"
#define kRemovePhotoButtonTitle                     @"Remove Photo"
#define kTakePhotoButtonTitle                       @"Take Photo"
#define kChooseFromLibraryButtonTitle               @"Choose From Library"

//Firebase Nodes
#define kUsersFirebaseNode                          @"users"
#define kGroupsFirebaseNode                         @"groups"
#define kMembersFirebaseNode                        @"members"
#define kNetworkConnectionNode                      @".info/connected"

//Firebase Fields
#define kUserEmailFirebaseField                     @"email"
#define kUserFirstNameFirebaseField                 @"first_name"
#define kUserLastNameFirebaseField                  @"last_name"
#define kUserCompletedRegistrationFirebaseField     @"completed_registration"
#define kProfileImageFirebaseField                  @"profile_image"

//Image Assets
#define kProfileLogoImage                           @"profile_logo"

//Notifications
#define kGroupDataUpdatedNotification               @"Group Data Updated"
#define kNewGroupNotification                       @"New Group"
#define kGroupRemovedNotification                   @"Group Removed"
#define kNoGroupsNotification                       @"No Groups"
