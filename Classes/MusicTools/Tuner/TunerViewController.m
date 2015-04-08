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

@interface TunerViewController () <FaceViewDataSource>

@property (nonatomic) int happiness; // 0 is out of tune; 100 is in tune
@property (weak, nonatomic) IBOutlet UILabel *labelPitch;
@property (weak, nonatomic) IBOutlet UILabel *labelCents;

@property (weak, nonatomic) IBOutlet FaceView *faceView;

@end

@implementation TunerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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

@end
