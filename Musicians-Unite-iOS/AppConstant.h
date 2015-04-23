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
#define kAddingMemberProgressMessage                @"Adding member..."

//Segue Identifiers
#define kLogoutSegueIdentifier                      @"Logout"
#define kLoginToGroupSegueIdentifier                @"LoginToGroups"
#define kRegisterToGroupSegueIdentifier             @"RegisterToGroups"
#define kChangePasswordSegueIdentifier              @"changePassword"
#define kDeleteAccountSegueIdentifier               @"deleteAccount"
#define kNewGroupSegueIdentifier                    @"newGroup"
#define kGroupTabsSegueIdentifier                   @"showGroupTabs"
#define kMemberManagementSegueIdentifier            @"viewMemberManagement"
#define kMetronomeSegueIdentifier                   @"viewMetronome"
#define kTaskDetailSegueIdentifier                  @"taskDetail"

//Cell Identifiers
#define kGroupCellIdentifier                        @"GroupCell"
#define kUserCellIdentifier                         @"UserCell"
#define kTaskCellIdentifier                         @"TaskCell"

//Error Messages
#define kError                                      @"Error"
#define kInvalidEmailPasswordError                  @"Invalid email and/or password"
#define kInvalidEmailError                          @"Invalid Email"
#define kInvalidPasswordError                       @"Invalid Password"
#define kInvalidTempoError                          @"Invalid Tempo"
#define kEmailTakenError                            @"Email is already taken"
#define kUserDoesNotExistError                      @"User does not exist"
#define kNetworkError                               @"Network Error"
#define kNoFirstNameError                           @"First name is required"
#define kNoCameraError                              @"Device has no camera"
#define kNoGroupNameError                           @"Group name is required"
#define kNoTaskTitleError                           @"Task title is required"
#define kMemberAlreadyExistsError                   @"Member already exists"

//Success Messages
#define kResetPasswordSuccessMessage                @"Password reset email sent!"
#define kUserDataSavedSuccessMessage                @"User Saved!"
#define kAccountDeletedSuccessMessage               @"Account Deleted!"
#define kAccountCreatedSuccessMessage               @"Account Created!"
#define kPasswordChangedSuccessMessage              @"Password Changed!"
#define kNewGroupSuccessMessage                     @"New Group!"
#define kGroupRemovedSuccessMessage                 @"Group Removed!"
#define kLoggedOutSuccessMessage                    @"Logged Out!"
#define kLoggedInSuccessMessage                     @"Logged In!"
#define kGroupSavedSuccessMessage                   @"Group Saved!"
#define kMemberAddedSuccessMessage                  @"Member Added!"
#define kTaskSavedSuccessMessage                    @"Task Saved!"
#define kTaskRemovedSuccessMessage                  @"Task Removed!"
#define kNewTaskSuccessMessage                      @"New Task!"
#define kTaskCompletedSuccessMessage                @"Task Completed!"

//Alert Messages
#define kForgotPasswordAlertMessage                 @"Please enter your email address"
#define kDeleteAccountAlertMessage                  @"Please enter your password"
#define kLeaveGroupAlertMessage                     @"All of your data will be removed from the group. Would you like to continue?"
#define kDeleteMemberAlertMessage                   @"Removing users will remove their data from the group. Would you like to continue?"

//Button Titles
#define kConfirmButtonTitle                         @"OK"
#define kCancelButtonTitle                          @"Cancel"
#define kRemovePhotoButtonTitle                     @"Remove Photo"
#define kTakePhotoButtonTitle                       @"Take Photo"
#define kChooseFromLibraryButtonTitle               @"Choose From Library"
#define kLeaveGroupButtonTitle                      @"Leave Group"
#define kCreateButtonTitle                          @"Create"
#define kSaveButtonTitle                            @"Save"

//View Titles
#define kGroupSettingsTitle                         @"Group Settings"
#define kPracticeListTitle                          @"Practice List"

//Table section headers
#define kCompletedTasksSectionHeader                @"Completed"
#define kIncompleteTasksSectionHeader               @"Incomplete"

//Firebase Nodes
#define kUsersFirebaseNode                          @"users"
#define kGroupsFirebaseNode                         @"groups"
#define kMembersFirebaseNode                        @"members"
#define kNetworkConnectionNode                      @".info/connected"
#define kTasksFirebaseNode                          @"tasks"

//Firebase Fields
#define kUserEmailFirebaseField                     @"email"
#define kUserFirstNameFirebaseField                 @"first_name"
#define kUserLastNameFirebaseField                  @"last_name"
#define kUserCompletedRegistrationFirebaseField     @"completed_registration"
#define kProfileImageFirebaseField                  @"profile_image"
#define kGroupNameFirebaseField                     @"name"
#define kTaskTitleFirebaseField                     @"title"
#define kTaskTempoFirebaseField                     @"tempo"
#define kTaskNotesFirebaseField                     @"notes"
#define kTaskCompletedFirebaseField                 @"completed"

//Image Assets
#define kProfileLogoImage                           @"profile_logo"
#define kCheckboxImage                              @"checkbox"
#define kCompletedCheckboxImage                     @"checkbox_completed"

//Notifications
#define kGroupDataUpdatedNotification               @"Group Data Updated"
#define kNewGroupNotification                       @"New Group"
#define kGroupRemovedNotification                   @"Group Removed"
#define kNoGroupsNotification                       @"No Groups"
#define kGroupMemberRemovedNotification             @"Group Member Removed"
#define kNewGroupMemberNotification                 @"New Group Member"
#define kNewUserTaskNotification                    @"New User Task"
#define kNewGroupTaskNotification                   @"New Group Task"
#define kUserTaskRemovedNotification                @"User Task Removed"
#define kGroupTaskRemovedNotification               @"Group Task Removed"
#define kUserTaskDataUpdatedNotification            @"User Task Data Updated"
#define kGroupTaskDataUpdatedNotification           @"Group Task Data Updated"
#define kUserTaskCompletedNotification              @"User Task Completed"
#define kGroupTaskCompletedNotification             @"Group Task Completed"
