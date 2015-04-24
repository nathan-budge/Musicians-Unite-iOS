//
//  RecordingTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/3/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "RecordingTableViewController.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "Recording.h"
#import "User.h"
#import "Group.h"


@interface RecordingTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (assign) BOOL groupPickerIsShowing;

@property (assign) NSString *ownerID;

@property (weak, nonatomic) IBOutlet UITextField *fieldRecordingName;
@property (weak, nonatomic) IBOutlet UILabel *labelGroupName;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerGroups;

@end


@implementation RecordingTableViewController

//*****************************************************************************/
#pragma mark - Lazy instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if(!_ref){
        _ref =[[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fieldRecordingName.text = self.recording.name;
    
    if (self.group)
    {
        self.labelGroupName.text = self.group.name;
        self.ownerID = self.group.groupID;
    }
    else
    {
        if ([self.recording.ownerID isEqualToString:self.sharedData.user.userID])
        {
            self.labelGroupName.text = kUnassignedRecordingTitle;
            self.ownerID = self.sharedData.user.userID;
            
            [self.pickerGroups selectRow:0 inComponent:0 animated:YES];
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", self.recording.ownerID];
            NSArray *group = [self.sharedData.user.groups filteredArrayUsingPredicate:predicate];
            
            Group *foundGroup = [group objectAtIndex:0];
            self.labelGroupName.text = foundGroup.name;
            self.ownerID = foundGroup.groupID;
            
            [self.pickerGroups selectRow:[self.sharedData.user.groups indexOfObject:foundGroup] + 1 inComponent:0 animated:YES];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.group)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kGroupRecordingRemovedNotification
                                                   object:nil];
    }
    else
    {        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserRecordingRemovedNotification
                                                   object:nil];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionSave:(id)sender
{
    if ([self.fieldRecordingName.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:kNoRecordingNameError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kRecordingsFirebaseNode, self.recording.recordingID]];
        NSDictionary *updatedRecording = @{
                                           kRecordingNameFirebaseField: self.fieldRecordingName.text,
                                           kRecordingOwnerFirebaseField: self.ownerID ? self.ownerID : self.recording.ownerID,
                                           };
        [recordingRef updateChildValues:updatedRecording];
        
        if (!self.group)
        {
            Firebase *groupRecordingsRef;
            NSString *oldOwnerID = self.recording.ownerID;
            
            if ([oldOwnerID isEqualToString:self.sharedData.user.userID] && ![self.ownerID isEqualToString:self.sharedData.user.userID])
            {
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kGroupsFirebaseNode, self.ownerID, kRecordingsFirebaseNode]];
                [groupRecordingsRef updateChildValues:@{self.recording.recordingID:@YES}];
            }
            else if (![oldOwnerID isEqualToString:self.sharedData.user.userID] && [self.ownerID isEqualToString:self.sharedData.user.userID])
            {
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, oldOwnerID, kRecordingsFirebaseNode, self.recording.recordingID]];
                [groupRecordingsRef removeValue];
            }
            else if  (![oldOwnerID isEqualToString:self.sharedData.user.userID] && ![self.ownerID isEqualToString:self.sharedData.user.userID])
            {
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, oldOwnerID, kRecordingsFirebaseNode, self.recording.recordingID]];
                [groupRecordingsRef removeValue];
                
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kGroupsFirebaseNode, self.ownerID, kRecordingsFirebaseNode]];
                [groupRecordingsRef updateChildValues:@{self.recording.recordingID:@YES}];
            }
        }
        
        [Utilities greenToastMessage:kRecordingSavedSuccessMessage];
    }
}

- (IBAction)actionDelete:(id)sender
{
    Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kRecordingsFirebaseNode, self.recording.recordingID]];
    
    if (self.group)
    {
        if ([self.recording.creatorID isEqualToString:self.group.groupID]) //If creator is group, remove recording
        {
            [recordingRef removeValue];
        }
        else //Otherwise, assign creator as owner
        {
            [recordingRef updateChildValues:@{kRecordingOwnerFirebaseField:self.recording.creatorID}];
        }

        Firebase *groupRecordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kRecordingsFirebaseNode, self.recording.recordingID]];
        [groupRecordingRef removeValue];
    }
    else
    {
        if ([self.recording.ownerID isEqualToString:self.sharedData.user.userID]) //If recoding is owner by the user, delete the recording
        {
            [recordingRef removeValue];
        }
        else //Otherwise, "give" the recording to the group by assigning creator as group
        {
            [recordingRef updateChildValues:@{kRecordingCreatorFirebaseField:self.recording.ownerID}];
        }
        
        Firebase *userRecordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kUsersFirebaseNode, self.sharedData.user.userID, kRecordingsFirebaseNode, self.recording.recordingID]];
        [userRecordingRef removeValue];
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kUserRecordingRemovedNotification])
    {
        if ([notification.object isEqual:self.recording])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if ([[notification name] isEqualToString:kGroupRecordingRemovedNotification])
    {
        NSArray *removedRecordingData = notification.object;
        if ([[removedRecordingData objectAtIndex:1] isEqual:self.recording])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

//*****************************************************************************/
#pragma mark - Picker data source methods
//*****************************************************************************/

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.sharedData.user.groups.count + 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row == 0)
    {
        return kUnassignedRecordingTitle;
    }
    Group *group = [self.sharedData.user.groups objectAtIndex:row - 1];
    return group.name;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (row == 0)
    {
        self.labelGroupName.text = kUnassignedRecordingTitle;
        self.ownerID = self.sharedData.user.userID;
    }
    else
    {
        Group *group = [self.sharedData.user.groups objectAtIndex:row - 1];
        self.labelGroupName.text = group.name;
        self.ownerID = group.groupID;
    }
}


//*****************************************************************************/
#pragma mark - Table view methods

//Adapted from https://github.com/costescv/InlineDatePicker
//*****************************************************************************/

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = self.tableView.rowHeight;
    
    if (indexPath.row == kDatePickerIndex){
        
        height = self.groupPickerIsShowing ? kDatePickerCellHeight : 0.0f;
        
    }
    
    return height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 1 && !self.group){
        
        if (self.groupPickerIsShowing)
        {
            [self hideDatePickerCell];
        }
        else
        {
            [self showDatePickerCell];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showDatePickerCell {
    
    self.groupPickerIsShowing = YES;
    
    [self.tableView beginUpdates];
    
    [self.tableView endUpdates];
    
    self.pickerGroups.hidden = NO;
    self.pickerGroups.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
        
        self.pickerGroups.alpha = 1.0f;
        
    }];
}

- (void)hideDatePickerCell {
    
    self.groupPickerIsShowing = NO;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.pickerGroups.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         self.pickerGroups.hidden = YES;
                     }];
}


//*****************************************************************************/
#pragma mark - Keyboard Handling
//*****************************************************************************/

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    return YES;
}


@end
