//
//  TunerViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/8/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from Happiness L6 http://web.stanford.edu/class/cs193p/cgi-bin/drupal/

#import "TunerViewController.h"
#import "FaceView.h"
#import "AppConstant.h"

@interface TunerViewController () <FaceViewDataSource>

@property (nonatomic) int happiness; // 0 is out of tune; 100 is in tune
@property (weak, nonatomic) IBOutlet UILabel *labelPitch;
@property (weak, nonatomic) IBOutlet UILabel *labelCents;

@property (weak, nonatomic) IBOutlet FaceView *faceView;

//@property (nonatomic) AVAudioRecorder

@end

@implementation TunerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Inside View Did Load.");
    audioManager = [AudioController sharedAudioManager];
    NSLog(@"Loaded Audio Manager.");
    audioManager.delegate = self;
    autoCorrelator = [[PitchDetector alloc] initWithSampleRate:audioManager.audioFormat.mSampleRate lowBoundFreq:30 hiBoundFreq:4500 andDelegate:self];
    medianPitchFollow = [[NSMutableArray alloc] initWithCapacity:22];
    self.happiness = 50;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.title = @"Tuner";
}

-(void)setHappiness:(int)happiness
{
    _happiness = MIN(MAX(happiness, 0), 100);
    
    self.labelCents.text = [NSString stringWithFormat:@"%d",happiness]; //USED FOR TESTING -- REMOVE WHEN IMPLEMENTING TUNER
    
    [self.faceView setNeedsDisplay];
}

- (void)setFaceView:(FaceView *)faceView
{
    _faceView = faceView;
    
    self.faceView.dataSource = self;
    
    //USED FOR TESTING -- REMOVE WHEN IMPLEMENTING TUNER
    [self.faceView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(handleHappinessGesture:)]];
}

//USED FOR TESTING -- REMOVE WHEN IMPLEMENTING TUNER
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

//The 
- (void) updatedPitch:(float)frequency {
    
    double value = frequency;
    
    
    
    //############ DATA SMOOTHING ###############
    //###     The following code averages previous values  ##
    //###  received by the pitch follower by using a             ##
    //###  median filter. Provides sub cent precision!          ##
    //#############################################
    
    NSNumber *nsnum = [NSNumber numberWithDouble:value];
    [medianPitchFollow insertObject:nsnum atIndex:0];
    
    if(medianPitchFollow.count>22) {
        [medianPitchFollow removeObjectAtIndex:medianPitchFollow.count-1];
    }
    double median = 0;
    
    
    
    if(medianPitchFollow.count>=2) {
        NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        NSMutableArray *tempSort = [NSMutableArray arrayWithArray:medianPitchFollow];
        [tempSort sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
        
        if(tempSort.count%2==0) {
            double first = 0, second = 0;
            first = [[tempSort objectAtIndex:tempSort.count/2-1] doubleValue];
            second = [[tempSort objectAtIndex:tempSort.count/2] doubleValue];
            median = (first+second)/2;
            value = median;
        } else {
            median = [[tempSort objectAtIndex:tempSort.count/2] doubleValue];
            value = median;
        }
        
        [tempSort removeAllObjects];
        tempSort = nil;
    }
    
    self.labelPitch.text = [NSString stringWithFormat:@"%3.1f Hz", value];
    
}

-(void) receivedAudioSamples:(SInt16 *)samples length:(int)len {
    [autoCorrelator addSamples:samples inNumberFrames:len];
}


@end
