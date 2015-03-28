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

#import "AppConstant.h"

#import "RecorderViewController.h"
#import "RecordingsTableViewController.h"
#import "NavigationDrawerViewController.h"

#import "User.h"
#import "Group.h"

@interface RecorderViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) User *user;

@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;

@property (weak, nonatomic) IBOutlet UIButton *buttonRecord;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlay;
@property (weak, nonatomic) IBOutlet UIButton *buttonSave;

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


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Audio Recorder";
    
    if (!self.group) {
        NavigationDrawerViewController *navigationDrawerViewController = (NavigationDrawerViewController *)self.slidingViewController.underLeftViewController;
        self.user = navigationDrawerViewController.user;
    }
    
    [self.buttonPlay setEnabled:NO];
    [self.buttonSave setEnabled:NO];
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MusicAudioRecording.m4a",
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


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionSave:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Recording" message:@"Enter a recording name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert addButtonWithTitle:@"Save"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        if ([textField.text isEqualToString:@""] == NO) {
            NSData *data = [NSData dataWithContentsOfFile:self.recorder.url.path];
            NSString *dataString = [data base64EncodedStringWithOptions:0];
            
            Firebase *recordingRef = [[self.ref childByAppendingPath:@"recordings"] childByAutoId];
            Firebase *ownerRef;
            NSString *ownerID;
            
            if (self.group) {
                ownerRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/recordings", self.group.groupID]];
                ownerID = self.group.groupID;
            } else {
                ownerRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/recordings", self.user.userID]];
                ownerID = self.user.userID;
            }
            
            NSDictionary *newRecording = @{
                                           @"name": textField.text,
                                           @"data": dataString,
                                           @"owner": ownerID,
                                           };
            
            [recordingRef setValue:newRecording];
            [ownerRef updateChildValues:@{recordingRef.key:@YES}];
            
            [SVProgressHUD showSuccessWithStatus:@"Recording created" maskType:SVProgressHUDMaskTypeBlack];
        }
    }
}

- (IBAction)actionRecord:(id)sender
{
    if (self.player.playing) {
        [self.player stop];
    }
    
    if (!self.recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        [self.recorder record];
        [self.buttonRecord setTitle:@"Stop" forState:UIControlStateNormal];
        [self.buttonPlay setEnabled:NO];
        [self.buttonSave setEnabled:NO];
        
    } else {
        
        [self.recorder stop];
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:NO error:nil];
        [self.buttonRecord setTitle:@"Record" forState:UIControlStateNormal];
        
        [self.buttonPlay setEnabled:YES];
        [self.buttonSave setEnabled:YES];
    }
}

- (IBAction)actionPlay:(id)sender
{
    if (!self.recorder.recording)
    {
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recorder.url error:nil];
        [self.player setDelegate:self];
        [self.player play];
        
    }
}

- (IBAction)actionRecordings:(id)sender
{
    if (self.group)
    {
        [self performSegueWithIdentifier:@"viewGroupRecordings" sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:@"viewUserRecordings" sender:self];
    }
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewUserRecordings"]) {
        RecordingsTableViewController *destViewController = segue.destinationViewController;
        destViewController.user = self.user;

    } else if ([segue.identifier isEqualToString:@"viewGroupRecordings"]) {
        RecordingsTableViewController *destViewController = segue.destinationViewController;
        destViewController.group = self.group;
        
    }
}


@end
