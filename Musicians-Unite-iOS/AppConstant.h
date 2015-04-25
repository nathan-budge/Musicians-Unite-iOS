//
//  AppConstant.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/14/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

//*****************************************************************************/
#pragma mark - Firebase URL
//*****************************************************************************/

#define FIREBASE_URL @"https://blazing-heat-4549.firebaseio.com"



//*****************************************************************************/
#pragma mark - Storyboard ids
//*****************************************************************************/

#define kMusicToolsNavigationController             @"MusicToolsNavigationController"
#define kPracticeListNavigationController           @"PracticeListNavigationController"
#define kUserSettingsNavigationController           @"UserSettingsNavigationController"



//*****************************************************************************/
#pragma mark - Segue identifiers
//*****************************************************************************/

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
#define kNewMessageSegueIdentifier                  @"newMessage"
#define kThreadDetailSegueIdentifier                @"viewThread"
#define kUserRecordingsSegueIdentifier              @"viewUserRecordings"
#define kGroupRecordingsSegueIdentifier             @"viewGroupRecordings"
#define kRecordingSegueIdentifier                   @"viewRecording"


//*****************************************************************************/
#pragma mark - Cell identifiers
//*****************************************************************************/

#define kGenericCellIdentifier                      @"cell"
#define kGroupCellIdentifier                        @"GroupCell"
#define kUserCellIdentifier                         @"UserCell"
#define kTaskCellIdentifier                         @"TaskCell"
#define kMessageCellIdentifier                      @"MessengerCell"



//*****************************************************************************/
#pragma mark - Status messages
//*****************************************************************************/

#define kLoggingOutProgressMessage                  @"Logging out..."
#define kLoggingInProgressMessage                   @"Logging in..."
#define kRegisteringProgressMessage                 @"Registering..."
#define kDeletingAccountProgressMessage             @"Deleting account..."
#define kChangingPasswordProgressMessage            @"Changing password..."
#define kAddingMemberProgressMessage                @"Adding member..."
#define kSavingRecordingProgressMessage             @"Saving recording..."



//*****************************************************************************/
#pragma mark - Error messages
//*****************************************************************************/

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
#define kThreadAlreadyExistsError                   @"Thread already exists"
#define kNoThreadMembersSelectedError               @"No members selected"
#define kNoRecordingNameError                       @"Recording name is required"



//*****************************************************************************/
#pragma mark - Success messages
//*****************************************************************************/

#define kNewGroupSuccessMessage                     @"New Group:"
#define kGroupRemovedSuccessMessage                 @"Group Removed:"
#define kGroupSavedSuccessMessage                   @"Group Saved"

#define kNewTaskSuccessMessage                      @"New Task"
#define kTaskRemovedSuccessMessage                  @"Task Removed"
#define kTaskSavedSuccessMessage                    @"Task Saved"

#define kMessageRemovedSuccessMessage               @"Message Removed"
#define kNewMessageThreadSuccessMessage             @"New Thread"
#define kMessageThreadRemovedSuccessMessage         @"Thread Removed"

#define kNewRecordingSuccessMessage                 @"New Recording"
#define kRecordingRemovedSuccessMessage             @"Recording Removed"
#define kRecordingSavedSuccessMessage               @"Recording Saved"

#define kUserDataSavedSuccessMessage                @"User Saved!"

#define kLoggedInSuccessMessage                     @"Logged In!"
#define kLoggedOutSuccessMessage                    @"Logged Out!"

#define kAccountCreatedSuccessMessage               @"Account Created!"
#define kAccountDeletedSuccessMessage               @"Account Deleted!"

#define kResetPasswordSuccessMessage                @"Password reset email sent!"
#define kPasswordChangedSuccessMessage              @"Password Changed!"



//*****************************************************************************/
#pragma mark - Alert messages
//*****************************************************************************/

#define kForgotPasswordAlertMessage                 @"Please enter your email address"
#define kDeleteAccountAlertMessage                  @"Please enter your password"
#define kLeaveGroupAlertMessage                     @"All of your data will be removed from the group. Would you like to continue?"
#define kDeleteMemberAlertMessage                   @"Removing users will remove their data from the group. Would you like to continue?"

#define kSaveRecordingAlertMessageTitle             @"Save Recording"
#define kSaveRecordingAlertMessage                  @"Enter a recording name"



//*****************************************************************************/
#pragma mark - Button titles
//*****************************************************************************/

#define kConfirmButtonTitle                         @"OK"
#define kCancelButtonTitle                          @"Cancel"
#define kRemovePhotoButtonTitle                     @"Remove Photo"
#define kTakePhotoButtonTitle                       @"Take Photo"
#define kChooseFromLibraryButtonTitle               @"Choose From Library"
#define kLeaveGroupButtonTitle                      @"Leave Group"
#define kCreateButtonTitle                          @"Create"
#define kSaveButtonTitle                            @"Save"
#define kSendButtonTitle                            @"Send"
#define kDeleteButtonTitle                          @"Delete"
#define kStopButtonTitle                            @"Stop"
#define kRecordButtonTitle                          @"Record"



//*****************************************************************************/
#pragma mark - Tab titles
//*****************************************************************************/

#define kGroupSettingsTitle                         @"Group Settings"
#define kPracticeListTitle                          @"Practice List"
#define kMessagesTitle                              @"Messages"
#define kAudioRecorderTitle                         @"Audio Recorder"



//*****************************************************************************/
#pragma mark - Table view section headers
//*****************************************************************************/

#define kCompletedTasksSectionHeader                @"Completed"
#define kIncompleteTasksSectionHeader               @"Incomplete"
#define kSelectMembersSectionHeader                 @"Select Members"
#define kNoRegisterdMembersSectionHeader            @"No Registered Members"



//*****************************************************************************/
#pragma mark - Firebase Nodes
//*****************************************************************************/

#define kNetworkConnectionNode                      @".info/connected"
#define kUsersFirebaseNode                          @"users"
#define kGroupsFirebaseNode                         @"groups"
#define kMembersFirebaseNode                        @"members"
#define kTasksFirebaseNode                          @"tasks"
#define kMessageThreadsFirebaseNode                 @"message_threads"
#define kMessagesFirebaseNode                       @"messages"
#define kRecordingsFirebaseNode                     @"recordings"



//*****************************************************************************/
#pragma mark - Firebase Fields
//*****************************************************************************/

#define kProfileImageFirebaseField                  @"profile_image"

#define kUserEmailFirebaseField                     @"email"
#define kUserFirstNameFirebaseField                 @"first_name"
#define kUserLastNameFirebaseField                  @"last_name"
#define kUserCompletedRegistrationFirebaseField     @"completed_registration"

#define kGroupNameFirebaseField                     @"name"

#define kTaskTitleFirebaseField                     @"title"
#define kTaskTempoFirebaseField                     @"tempo"
#define kTaskNotesFirebaseField                     @"notes"
#define kTaskCompletedFirebaseField                 @"completed"
#define kTaskGroupFirebaseField                     @"group"

#define kMessageSenderFirebaseField                 @"sender"
#define kMessageTextFirebaseField                   @"text"
#define kThreadForMessageFirebaseField              @"thread"

#define kRecordingNameFirebaseField                 @"name"
#define kRecordingDataFirebaseField                 @"data"
#define kRecordingOwnerFirebaseField                @"owner"
#define kRecordingCreatorFirebaseField              @"creator"
#define kRecordingGroupFirebaseField                @"group"



//*****************************************************************************/
#pragma mark - Notifications
//*****************************************************************************/

#define kInitialLoadCompletedNotification           @"Initial Load Completed"

#define kNewGroupNotification                       @"New Group"
#define kGroupRemovedNotification                   @"Group Removed"
#define kGroupDataUpdatedNotification               @"Group Data Updated"
#define kNoGroupsNotification                       @"No Groups"

#define kNewGroupMemberNotification                 @"New Group Member"
#define kGroupMemberRemovedNotification             @"Group Member Removed"

#define kNewMessageThreadNotification               @"New Thread"
#define kMessageThreadRemovedNotification           @"Thread Removed"

#define kNewMessageNotification                     @"New Message"
#define kMessageRemovedNotification                 @"Message Removed"

#define kNewUserTaskNotification                    @"New User Task"
#define kUserTaskRemovedNotification                @"User Task Removed"
#define kUserTaskDataUpdatedNotification            @"User Task Data Updated"
#define kUserTaskCompletedNotification              @"User Task Completed"

#define kNewGroupTaskNotification                   @"New Group Task"
#define kGroupTaskRemovedNotification               @"Group Task Removed"
#define kGroupTaskDataUpdatedNotification           @"Group Task Data Updated"
#define kGroupTaskCompletedNotification             @"Group Task Completed"

#define kNewUserRecordingNotification               @"New User Recording"
#define kUserRecordingRemovedNotification           @"User Recording Removed"
#define kUserRecordingDataUpdatedNotification       @"User Recording Data Updated"

#define kNewGroupRecordingNotification              @"New Group Recording"
#define kGroupRecordingRemovedNotification          @"Group Recording Removed"
#define kGroupRecordingDataUpdatedNotification      @"Group Recording Data Updated"



//*****************************************************************************/
#pragma mark - Image Assets
//*****************************************************************************/

#define kProfileLogoImage                           @"profile_logo"
#define kCheckboxImage                              @"checkbox"
#define kCompletedCheckboxImage                     @"checkbox_completed"

//*****************************************************************************/
#pragma mark - Pitch Constants
//*****************************************************************************/

#define FREQ_C0  16.35;
#define FREQ_DB0 17.32;
#define FREQ_D0  18.35;
#define FREQ_EB0 19.45;
#define FREQ_E0  20.60;
#define FREQ_F0  21.83;
#define FREQ_GB0 23.12;
#define FREQ_G0  24.50;
#define FREQ_AB0 25.96;
#define FREQ_A0  27.50;
#define FREQ_BB0 29.14;
#define FREQ_B0  30.87;


//*****************************************************************************/
#pragma mark - Misc
//*****************************************************************************/

#define kDefaultRecordingName                       @"MusicAudioRecording.m4a"
#define kUnassignedRecordingTitle                   @"Unassigned"
#define kAudioPlayerInitialTimeElapsed              @"0:00"    

#define kGroupPickerIndex 2
#define kGroupPickerCellHeight 164

