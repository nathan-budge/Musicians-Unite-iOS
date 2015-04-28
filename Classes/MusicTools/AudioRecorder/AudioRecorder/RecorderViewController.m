//
//  RecorderViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SVProgressHUD.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "RecorderViewController.h"
#import "RecordingsTableViewController.h"

#import "User.h"
#import "Group.h"
#import "Recording.h"


@interface RecorderViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) SharedData *sharedData;

@property (assign) NSString *recordingID;

@property (assign) BOOL isPlaying;

@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;

@property (weak, nonatomic) IBOutlet UIButton *buttonRecord;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlay;
@property (weak, nonatomic) IBOutlet UIButton *buttonSave;
@property (weak, nonatomic) IBOutlet UIButton *buttonRecordings;

@end


@implementation RecorderViewController

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
    
    [self.buttonPlay setEnabled:NO];
    [self.buttonSave setEnabled:NO];
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               kDefaultRecordingName,
                               nil];
    
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItems = nil;
    self.tabBarController.title = kAudioRecorderTitle;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewUserRecordingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewGroupRecordingNotification
                                               object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionSave:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kSaveRecordingAlertMessageTitle message:kSaveRecordingAlertMessage delegate:self cancelButtonTitle:kCancelButtonTitle otherButtonTitles: kSaveButtonTitle, nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (IBAction)actionRecord:(id)sender
{
    if (self.player.playing)
    {
        [self.player stop];
    }
    
    if (!self.recorder.recording)
    {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        [self.recorder record];
        [self.buttonRecord setBackgroundImage:[UIImage imageNamed:@"button_record_active"] forState:UIControlStateNormal];
        
        [self.buttonPlay setBackgroundImage:[UIImage imageNamed:@"button_play"] forState:UIControlStateNormal];
        self.isPlaying = NO;
        
        [self.buttonPlay setEnabled:NO];
        [self.buttonSave setEnabled:NO];
        [self.buttonRecordings setEnabled:NO];
    }
    else
    {
        [self.recorder stop];
        
        [self.buttonRecord setBackgroundImage:[UIImage imageNamed:@"button_record_inactive"] forState:UIControlStateNormal];
        
        [self.buttonPlay setEnabled:YES];
        [self.buttonSave setEnabled:YES];
        [self.buttonRecordings setEnabled:YES];
    }
}

- (IBAction)actionPlay:(id)sender
{
    if (!self.recorder.recording)
    {
        if (self.isPlaying)
        {
            [self.buttonPlay setBackgroundImage:[UIImage imageNamed:@"button_play"] forState:UIControlStateNormal];
            [self.player stop];
            self.isPlaying = NO;
        }
        else
        {
            [self.buttonPlay setBackgroundImage:[UIImage imageNamed:@"button_stop"] forState:UIControlStateNormal];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recorder.url error:nil];
            [self.player setDelegate:self];
            [self.player play];
            self.isPlaying = YES;
            NSThread *playRecording = [[NSThread alloc] initWithTarget:self selector:@selector(playRecording) object:nil];
            [playRecording start];
        }
    }
}

- (void)playRecording
{
    [NSThread sleepForTimeInterval:self.player.duration];
    
    [self.buttonPlay setBackgroundImage:[UIImage imageNamed:@"button_play"] forState:UIControlStateNormal];
    [self.player stop];
    self.isPlaying = NO;
    
    [NSThread exit];
}

- (IBAction)actionRecordings:(id)sender
{
    if (self.group)
    {
        [self performSegueWithIdentifier:kGroupRecordingsSegueIdentifier sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:kUserRecordingsSegueIdentifier sender:self];
    }
}


//*****************************************************************************/
#pragma mark - Save recording alert view
//*****************************************************************************/

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        if ([textField.text isEqualToString:@""] == NO) {
            
            [SVProgressHUD showWithStatus:kSavingRecordingProgressMessage maskType:SVProgressHUDMaskTypeBlack];
            
            NSData *data = [NSData dataWithContentsOfFile:self.recorder.url.path];
            NSString *dataString = [data base64EncodedStringWithOptions:0];
            
            Firebase *recordingRef = [[self.ref childByAppendingPath:kRecordingsFirebaseNode] childByAutoId];
            self.recordingID = recordingRef.key;
            
            Firebase *creatorRef;
            NSString *creatorID;
            NSDictionary *newRecording;
            
            if (self.group)
            {
                creatorRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kGroupsFirebaseNode, self.group.groupID, kRecordingsFirebaseNode]];
                creatorID = self.group.groupID;
                
                newRecording = @{
                                   kRecordingNameFirebaseField: textField.text,
                                   kRecordingDataFirebaseField: dataString,
                                   kRecordingOwnerFirebaseField: creatorID,
                                   kRecordingCreatorFirebaseField: creatorID,
                                   kRecordingGroupFirebaseField:self.group.groupID,
                                   };
            }
            else
            {
                creatorRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kUsersFirebaseNode, self.sharedData.user.userID, kRecordingsFirebaseNode]];
                creatorID = self.sharedData.user.userID;
                
                newRecording = @{
                                   kRecordingNameFirebaseField: textField.text,
                                   kRecordingDataFirebaseField: dataString,
                                   kRecordingOwnerFirebaseField: creatorID,
                                   kRecordingCreatorFirebaseField: creatorID,
                                   };
            }
            
            
            
            [recordingRef setValue:newRecording];
            
            [creatorRef updateChildValues:@{recordingRef.key:@YES}];
        }
        else
        {
            [SVProgressHUD showErrorWithStatus:kNoRecordingNameError maskType:SVProgressHUDMaskTypeBlack];
        }
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewUserRecordingNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            Recording *newRecording = notification.object;
            if ([newRecording.recordingID isEqualToString:self.recordingID])
            {
                self.recordingID = nil;
                [SVProgressHUD dismiss];
                [Utilities greenToastMessage:kNewRecordingSuccessMessage];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kNewGroupRecordingNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            NSArray *newRecordingData = notification.object;
            Recording *newRecording = [newRecordingData objectAtIndex:1];
            if ([newRecording.recordingID isEqualToString:self.recordingID])
            {
                self.recordingID = nil;
                [SVProgressHUD dismiss];
            }
            
        });
    }
}

//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kGroupRecordingsSegueIdentifier])
    {
        RecordingsTableViewController *destViewController = segue.destinationViewController;
        destViewController.group = self.group;
        destViewController.hidesBottomBarWhenPushed = YES;
    }
}


@end
