//
//  RecordingTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/3/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "RecordingTableViewController.h"

#import "AppConstant.h"

#import "Recording.h"
#import "User.h"
#import "Group.h"

@interface RecordingTableViewController ()

@property (nonatomic) Firebase *ref;

@property (weak, nonatomic) IBOutlet UITextField *fieldRecordingName;
@property (weak, nonatomic) IBOutlet UILabel *labelGroupName;

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
            self.labelGroupName.text = @"Unassigned";
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID=%@", self.recording.ownerID];
            NSArray *group = [self.user.groups filteredArrayUsingPredicate:predicate];
            
            Group *foundGroup = [group objectAtIndex:0];
            self.labelGroupName.text = foundGroup.name;
        }
    }
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionSave:(id)sender
{
    if ([self.fieldRecordingName.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Title required" maskType:SVProgressHUDMaskTypeBlack];
        
    }
    else
    {
        Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", self.recording.recordingID]];
        
        NSDictionary *updatedRecording = @{
                                           @"name": self.fieldRecordingName.text,
                                      };
        
        [recordingRef updateChildValues:updatedRecording];
        
        [SVProgressHUD showSuccessWithStatus:@"Recording saved" maskType:SVProgressHUDMaskTypeBlack];
        
        [self dismissKeyboard];
    }
}

- (IBAction)actionDelete:(id)sender
{
    if (self.group)
    {
        Firebase *groupRecordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings/%@", self.group.groupID, self.recording.recordingID]];
        [groupRecordingRef removeValue];
    }
    
    if (self.user)
    {
        Firebase *userRecordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/recordings/%@", self.user.userID, self.recording.recordingID]];
        [userRecordingRef removeValue];
    }
    
    Firebase *recordingRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"recordings/%@", self.recording.recordingID]];
    [recordingRef removeValue];
    
    [SVProgressHUD showSuccessWithStatus:@"Recording deleted" maskType:SVProgressHUDMaskTypeBlack];
    
    [self dismissKeyboard];
    
    [self.navigationController popViewControllerAnimated:YES];
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
