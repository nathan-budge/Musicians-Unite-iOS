//
//  TunerViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/8/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from Happiness L6 http://web.stanford.edu/class/cs193p/cgi-bin/drupal/
//  and from Simon Sings https://sites.google.com/site/musicandspecialeducation/home/resources/related-website/music-skill-games/simon-sings

#import "TunerViewController.h"
#import "FaceView.h"
#import "AppConstant.h"

@interface TunerViewController () <FaceViewDataSource>

@property (nonatomic) double happiness; // 0 is out of tune; 100 is in tune
@property (weak, nonatomic) IBOutlet UILabel *labelPitch;
@property (weak, nonatomic) IBOutlet UILabel *labelCents;

@property (weak, nonatomic) IBOutlet FaceView *faceView;

- (void)startAudio;
- (void)stopAudio;

@end

@implementation TunerViewController

void interruptionListenerCallback(void *inUserData, UInt32 interruptionState)
{
    TunerViewController* controller = (__bridge TunerViewController*) inUserData;
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        [controller beginInterruption];
    }
    else if (interruptionState == kAudioSessionEndInterruption)
    {
        [controller endInterruption];
    }
}

- (void)beginInterruption
{
    [self stopAudio];
    if (recorder == nil) {
        AudioSessionSetActive(false);
    }
}

- (void)endInterruption
{
    [self startAudio];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.happiness = 0;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.title = @"Tuner";
    [self startAudio];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopAudio];
}

- (void)setFaceView:(FaceView *)faceView
{
    _faceView = faceView;
    
    self.faceView.dataSource = self;
}


- (void) handleHappinessGesture: (UIPanGestureRecognizer *) gesture
{
    if(gesture.state == UIGestureRecognizerStateChanged ||
       gesture.state == UIGestureRecognizerStateEnded){
        CGPoint translation = [gesture translationInView: self.faceView];
        self.happiness -= translation.y / 2;
        [gesture setTranslation:CGPointZero inView:self.faceView];
    }
}

- (float)smileForFaceView:(FaceView *)sender
{
    return (self.happiness - 50.0) / 50.0;
}

- (void)startAudio
{
    if (recorder == nil)  // should always be the case
    {
        AudioSessionInitialize(
                               NULL,
                               NULL,
                               interruptionListenerCallback,
                               (__bridge void *)(self)
                               );
        
        UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        AudioSessionSetProperty(
                                kAudioSessionProperty_AudioCategory,
                                sizeof(sessionCategory),
                                &sessionCategory
                                );
        
        AudioSessionSetActive(true);
        
        recorder = [[Recorder alloc] init];
        recorder.delegate = self;
        [recorder startRecording];
    }
}

- (void)stopAudio
{
    if (recorder != nil)
    {
        [recorder stopRecording];
        recorder = nil;
    }
}

- (void)recordedFreq:(float)freq;
{
    detectedFreq = freq;
    deltaFreq = 0.0f;
    
    if (freq > 100.0f)  // to avoid environmental noise
    {
        double cents = [self convertToCents:detectedFreq];
        self.happiness = 100 - fabs(cents);
        self.labelCents.text = [NSString stringWithFormat:@"%.2f", cents ];
        [self.faceView setNeedsDisplay];
    }
}

-(double) convertToCents:(double)hertz {
    double closestFreq= 0.0;
    NSString *closestPitch = @"";
    double minDistance = INFINITY;
    int range = 0;
    
    double ab0 = FREQ_AB0;
    double a0 = FREQ_A0;
    double bb0 = FREQ_BB0;
    double b0 = FREQ_B0;
    double c0 = FREQ_C0;
    double db0 = FREQ_DB0;
    double d0 = FREQ_D0;
    double eb0 = FREQ_EB0;
    double e0 = FREQ_E0;
    double f0 = FREQ_F0;
    double gb0 = FREQ_GB0;
    double g0 = FREQ_G0;
    
    NSMutableDictionary *octaveZeroValues = [NSMutableDictionary dictionary];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:ab0] forKey:@"Ab"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:a0] forKey:@"A"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:bb0] forKey:@"Bb"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:b0] forKey:@"B"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:c0] forKey:@"C"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:db0] forKey:@"Db"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:d0] forKey:@"D"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:eb0] forKey:@"Eb"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:e0] forKey:@"E"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:f0] forKey:@"F"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:gb0] forKey:@"Gb"];
    [octaveZeroValues setValue:[NSNumber numberWithDouble:g0] forKey:@"G"];
    
    //    NSDictionary *octaveZeroValues = [NSDictionary dictionaryWithObjectsAndKeys:
    //                                      [NSNumber numberWithDouble:a0], @"A",
    //                                      [NSNumber numberWithDouble:b0], @"B",
    //                                      [NSNumber numberWithDouble:c0], @"C",
    //                                      [NSNumber numberWithDouble:d0], @"D",
    //                                      [NSNumber numberWithDouble:e0], @"E",
    //                                      [NSNumber numberWithDouble:f0], @"F",
    //                                      [NSNumber numberWithDouble:g0], @"G",
    //                                      nil];
    
    //    NSArray *octaveZeroValues = [NSArray arrayWithObjects:
    //                           [NSNumber numberWithFloat:a0], "A0",
    //                           [NSNumber numberWithFloat:b0],
    //                           [NSNumber numberWithFloat:c0],
    //                           [NSNumber numberWithFloat:d0],
    //                           [NSNumber numberWithFloat:e0],
    //                           [NSNumber numberWithFloat:f0],
    //                           [NSNumber numberWithFloat:g0],
    //                           nil];
    
    BOOL octaveFound = NO;
    int octave = 0;
    while (!octaveFound && octave < 8) {
        if (hertz < (b0 * pow(2, octave) + (c0 * pow(2, octave + 1))) / 2) {
            octaveFound = YES;
        }
        octave++;
    }
    range = octaveFound ? octave - 1 : 8;
    for (NSString *octaveZeroPitch in octaveZeroValues) {
        double octaveZeroValue = [[octaveZeroValues objectForKey:octaveZeroPitch] doubleValue];
        double actualOctaveValue = octaveZeroValue * pow(2, range);
        double distanceToHertzValue = ABS(hertz - actualOctaveValue);
        if (distanceToHertzValue < minDistance) {
            minDistance = distanceToHertzValue;
            closestFreq = actualOctaveValue;
            closestPitch = octaveZeroPitch;
        }
    }
    self.labelPitch.text = hertz < 0 ? @"--" : [NSString stringWithFormat:@"%@%d", closestPitch, range];
    
    return 1200 * 3.322038403 * log10(hertz / closestFreq);
}

@end
