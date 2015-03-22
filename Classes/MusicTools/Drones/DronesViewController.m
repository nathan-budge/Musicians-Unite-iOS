//
//  DronesViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/19/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from https://github.com/MMercieca/Handshake/blob/master/Handshake/ToneGenerator.m

#import "DronesViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "AppConstant.h"

#define SAMPLE_RATE 44100

#define FREQ_A0  27.5;
#define FREQ_BB0 29.1352;
#define FREQ_B0  30.8677;
#define FREQ_C0  32.7032;
#define FREQ_DB0 34.6478;
#define FREQ_D0  36.7081;
#define FREQ_EB0 38.8909;
#define FREQ_E0  41.2034;
#define FREQ_F0  43.6535;
#define FREQ_GB0 46.2493;
#define FREQ_G0  48.9994;
#define FREQ_AB0 51.9131;

@interface DronesViewController ()

@property (nonatomic) double frequency;
@property (nonatomic) double theta;
@property (nonatomic) AVAudioSession *audioSession;
@property (nonatomic) AudioComponentInstance toneUnit;

@end

@implementation DronesViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    DronesViewController* dronesViewController = (__bridge DronesViewController*)inClientData;
    [dronesViewController stop];
}

- (IBAction)actionC:(id)sender {
    self.frequency = FREQ_C0;
}


- (IBAction)actionG:(id)sender {
    self.frequency = FREQ_G0;
}


- (IBAction)actionD:(id)sender {
    self.frequency = FREQ_D0;
}

- (IBAction)actionA:(id)sender {
    self.frequency = FREQ_A0;
}

- (IBAction)actionE:(id)sender {
    self.frequency = FREQ_E0;
}

- (IBAction)actionB:(id)sender {
    self.frequency = FREQ_B0;
}

- (IBAction)actionGb:(id)sender {
    self.frequency = FREQ_GB0;
}

- (IBAction)actionDb:(id)sender {
    self.frequency = FREQ_DB0;
}

- (IBAction)actionAb:(id)sender {
    self.frequency = FREQ_AB0;
}

- (IBAction)actionEb:(id)sender {
    self.frequency = FREQ_EB0;
}

- (IBAction)actionBb:(id)sender {
    self.frequency = FREQ_BB0;
}

- (IBAction)actionF:(id)sender {
    self.frequency = FREQ_F0;
}

- (IBAction)actionPlay:(id)sender {
    
    if (self.toneUnit) {
        [self stop];
        
    } else {
        [self.audioSession setActive:true error:nil];
        
        // Create the audio unit as shown above
        [self createToneUnit];
        
        // Start playback
        AudioOutputUnitStart(_toneUnit);
        
    }
    
    
}

-(void)stop
{
    if (self.toneUnit)
    {
        AudioOutputUnitStop(self.toneUnit);
        AudioUnitUninitialize(self.toneUnit);
        AudioComponentInstanceDispose(self.toneUnit);
        self.toneUnit = nil;
    }
    
    [self.audioSession setActive:false error:nil];
}

- (void)createToneUnit
{
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &_toneUnit);
    //NSAssert1(toneUnit, @"Error creating unit: %ld", err);
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void *)self;
    err = AudioUnitSetProperty(self.toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = SAMPLE_RATE;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (self.toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
}

OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
    // Fixed amplitude is good enough for our purposes
    const double amplitude = 1;
    
    // Get the tone parameters out of the view controller
    //ToneGeneratorViewController *viewController = (ToneGeneratorViewController *)inRefCon;
    DronesViewController *toneGenerator = (__bridge DronesViewController*)inRefCon;
    double theta = toneGenerator->_theta;
    double frequency = toneGenerator->_frequency;
    
    double theta_increment = 2.0 * M_PI * frequency / SAMPLE_RATE;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * amplitude;
        
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the theta back in the view controller
    toneGenerator->_theta = theta;
    
    return noErr;
}

@end
