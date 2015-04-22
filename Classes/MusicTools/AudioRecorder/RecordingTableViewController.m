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

#import "Recording.h"
#import "User.h"
#import "Group.h"


#define kUnassignedRecordingTitle   @"Unassigned"

#define kTitleError                 @"Title Required"
#define kRecordingSaved             @"Recording Saved"
#define kRecordingDeleted           @"Recording Deleted"

#define kRecordingNameKey           @"name"
#define kRecordingOwnerKey          @"owner"

#define kDatePickerIndex 2
#define kDatePickerCellHeight 164


@interface RecordingTableViewController ()

@property (nonatomic) Firebase *ref;

@property (assign) BOOL groupPickerIsShowing;
@property (assign) NSString *ownerID;

@property (weak, nonatomic) IBOutlet UITextField *fieldRecordingName;
@property (weak, nonatomic) IBOutlet UILabel *labelGroupName;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerGroups;

@property (nonatomic) SharedData *sharedData;

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
    
    if (self.user)
    {
        if ([self.recording.ownerID isEqualToString:self.user.userID])
        {
            self.labelGroupName.text = kUnassignedRecordingTitle;
            self.ownerID = self.user.userID;
            
            [self.pickerGroups selectRow:0 inComponent:0 animated:YES];
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", self.recording.ownerID];
            NSArray *group = [self.user.groups filteredArrayUsingPredicate:predicate];
            
            Group *foundGroup = [group objectAtIndex:0];
            self.labelGroupName.text = foundGroup.name;
            self.ownerID = foundGroup.groupID;
            
            [self.pickerGroups selectRow:[self.user.groups indexOfObject:foundGroup] + 1 inComponent:0 animated:YES];
        }
    }
    else if (self.group)
    {
        self.labelGroupName.text = self.group.name;
        self.ownerID = self.group.groupID;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Recording Data Updated"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Recording Removed"
                                               object:nil];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionSave:(id)sender
{
    if ([self.fieldRecordingName.text isEqualToString:@""])
    {
        [SVProgressHUD showErrorWithStatus:kTitleError maskType:SVProgressHUDMaskTypeBlack];
    }
    else
    {
        Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", self.recording.recordingID]];
        NSDictionary *updatedRecording = @{
                                           kRecordingNameKey: self.fieldRecordingName.text,
                                           kRecordingOwnerKey: self.ownerID ? self.ownerID : self.recording.ownerID,
                                           };
        [recordingRef updateChildValues:updatedRecording];
        
        if (self.user)
        {
            Firebase *groupRecordingsRef;
            NSString *oldOwnerID = self.recording.ownerID;
            
            if ([oldOwnerID isEqualToString:self.user.userID] && ![self.ownerID isEqualToString:self.user.userID])
            {
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings", self.ownerID]];
                [groupRecordingsRef updateChildValues:@{self.recording.recordingID:@YES}];
            }
            else if (![oldOwnerID isEqualToString:self.user.userID] && [self.ownerID isEqualToString:self.user.userID])
            {
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings/%@", oldOwnerID, self.recording.recordingID]];
                [groupRecordingsRef removeValue];
            }
            else if  (![oldOwnerID isEqualToString:self.user.userID] && ![self.ownerID isEqualToString:self.user.userID])
            {
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings/%@", oldOwnerID, self.recording.recordingID]];
                [groupRecordingsRef removeValue];
                
                groupRecordingsRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings", self.ownerID]];
                [groupRecordingsRef updateChildValues:@{self.recording.recordingID:@YES}];
            }
        }
    }
}

- (IBAction)actionDelete:(id)sender
{
    if (self.user)
    {
        if ([self.recording.ownerID isEqualToString:self.user.userID])
        {
            Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", self.recording.recordingID]];
            [recordingRef removeValue];
        }
        
        Firebase *userRecordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/recordings/%@", self.user.userID, self.recording.recordingID]];
        [userRecordingRef removeValue];
    }
    else if (self.group)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.recordingID=%@", self.recording.recordingID];
        NSArray *recording = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
        
        Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", self.recording.recordingID]];
        if (recording.count == 0)
        {
            [recordingRef removeValue];
        }
        else
        {
            [recordingRef updateChildValues:@{@"owner":self.sharedData.user.userID}];
        }
        
        Firebase *groupRecordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings/%@", self.group.groupID, self.recording.recordingID]];
        [groupRecordingRef removeValue];
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Recording Removed"])
    {
        [self dismissKeyboard];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if ([[notification name] isEqualToString:@"Recording Data Updated"])
    {
        NSDictionary *options = @{
                                  kCRToastTextKey : @"Recording Saved!",
                                  kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                  kCRToastBackgroundColorKey : [UIColor greenColor],
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                  };
        
        [CRToastManager showNotificationWithOptions:options
                                    completionBlock:^{
                                    }];
        
        [self dismissKeyboard];
        
        [self.navigationController popViewControllerAnimated:YES];
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
    return self.user.groups.count + 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row == 0)
    {
        return kUnassignedRecordingTitle;
    }
    Group *group = [self.user.groups objectAtIndex:row - 1];
    return group.name;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (row == 0)
    {
        self.labelGroupName.text = kUnassignedRecordingTitle;
        self.ownerID = self.user.userID;
    }
    else
    {
        Group *group = [self.user.groups objectAtIndex:row - 1];
        self.labelGroupName.text = group.name;
        self.ownerID = group.groupID;
    }
    
    NSLog(@"%@", self.ownerID);
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
    
    if (indexPath.row == 1 && self.user){
        
        if (self.groupPickerIsShowing){
            
            [self hideDatePickerCell];
            
        }else {
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
