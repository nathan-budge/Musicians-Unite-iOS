//
//  MetronomeViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/31/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "MetronomeViewController.h"
#import "MetronomeDots.h"

@interface MetronomeViewController ()

//Subviews
@property (weak, nonatomic) IBOutlet UIView *viewMeters;
@property (weak, nonatomic) IBOutlet UIView *viewBeats;
@property (weak, nonatomic) IBOutlet MetronomeDots *viewDots;

//Buttons
@property (weak, nonatomic) IBOutlet UIButton *buttonMeters;
@property (weak, nonatomic) IBOutlet UIButton *buttonBeat1;
@property (weak, nonatomic) IBOutlet UIButton *buttonBeat2;
@property (weak, nonatomic) IBOutlet UIButton *buttonBeat3;
@property (weak, nonatomic) IBOutlet UIButton *buttonBeat4;
@property (weak, nonatomic) IBOutlet UIButton *buttonBeats;

//Tempo
@property (weak, nonatomic) IBOutlet UILabel *labelTempo;
@property (weak, nonatomic) IBOutlet UIStepper *stepperTempo;

//Play
@property (weak, nonatomic) IBOutlet UIButton *buttonPlay;

@end


@implementation MetronomeViewController

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewDots.timeSignature = 1.4;
    [self.buttonMeters setTitle:@"1/4" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self.viewDots setNeedsDisplay];
    
    if (self.tempo)
    {
        self.stepperTempo.value = self.tempo;
    }
    else
    {
        self.stepperTempo.value = 60.0;
    }
    
    self.labelTempo.text = [NSString stringWithFormat:@"%.f",self.stepperTempo.value];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.title = @"Metronome";
}


//*****************************************************************************/
#pragma mark - Meter Buttons
//*****************************************************************************/

- (IBAction)actionMeter:(id)sender
{
    self.viewMeters.hidden = NO;
}

- (IBAction)actionCloseMeter:(id)sender
{
    [self dismissSubview:self.viewMeters];
}
- (IBAction)action2_2:(id)sender
{
    self.viewDots.timeSignature = 2.2;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"2/2" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action3_2:(id)sender
{
    self.viewDots.timeSignature = 3.2;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"3/2" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action4_2:(id)sender
{
    self.viewDots.timeSignature = 4.2;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"4/2" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action1_4:(id)sender
{
    self.viewDots.timeSignature = 1.4;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"1/4" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action2_4:(id)sender
{
    self.viewDots.timeSignature = 2.4;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"2/4" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action3_4:(id)sender
{
    self.viewDots.timeSignature = 3.4;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"3/4" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action4_4:(id)sender
{
    self.viewDots.timeSignature = 4.4;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"4/4" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action3_8:(id)sender
{
    [self dismissSubview:self.viewMeters];
    self.viewDots.timeSignature = 3.8;
    [self.buttonMeters setTitle:@"3/8" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self.viewDots setNeedsDisplay];
}

- (IBAction)action6_8:(id)sender
{
    self.viewDots.timeSignature = 6.8;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"6/8" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action9_8:(id)sender
{
    self.viewDots.timeSignature = 9.8;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"9/8" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}

- (IBAction)action12_8:(id)sender
{
    self.viewDots.timeSignature = 12.8;
    [self.viewDots setNeedsDisplay];
    [self.buttonMeters setTitle:@"12/8" forState:UIControlStateNormal];
    [self.buttonBeats setTitle:@"1" forState:UIControlStateNormal];
    [self dismissSubview:self.viewMeters];
}


//*****************************************************************************/
#pragma mark - Beat Buttons
//*****************************************************************************/

- (IBAction)actionBeat:(id)sender
{
    [self getBeats];
    self.viewBeats.hidden = NO;
}

- (IBAction)actionCloseBeats:(id)sender
{
    [self dismissSubview:self.viewBeats];
}

- (IBAction)actionBeat1:(id)sender
{
    [self.buttonBeats setTitle:self.buttonBeat1.titleLabel.text forState:UIControlStateNormal];
    [self dismissSubview:self.viewBeats];
}

- (IBAction)actionBeat2:(id)sender
{
    [self.buttonBeats setTitle:self.buttonBeat2.titleLabel.text forState:UIControlStateNormal];
    [self dismissSubview:self.viewBeats];
}

- (IBAction)actionBeat3:(id)sender
{
    [self.buttonBeats setTitle:self.buttonBeat3.titleLabel.text forState:UIControlStateNormal];
    [self dismissSubview:self.viewBeats];
}

- (IBAction)actionBeat4:(id)sender
{
    [self.buttonBeats setTitle:self.buttonBeat4.titleLabel.text forState:UIControlStateNormal];
    [self dismissSubview:self.viewBeats];
}


//*****************************************************************************/
#pragma mark - Tempo Stepper
//*****************************************************************************/


- (IBAction)actionChangeTempo:(id)sender
{
    self.labelTempo.text = [NSString stringWithFormat:@"%.f",self.stepperTempo.value];
}


//*****************************************************************************/
#pragma mark - Play Button
//*****************************************************************************/

- (IBAction)actionPlay:(id)sender
{
    //TODO
}


//*****************************************************************************/
#pragma mark - Helper Methods
//*****************************************************************************/

- (void)dismissSubview:(UIView *)subview
{
    subview.hidden = YES;
}

- (void)getBeats
{
    if (self.viewDots.timeSignature == 2.2 || self.viewDots.timeSignature == 3.2 || self.viewDots.timeSignature == 4.2) {
        self.buttonBeat3.hidden = NO;
        self.buttonBeat4.hidden = NO;
        
        //TODO: Add Images
        [self.buttonBeat1 setTitle:@"1" forState:UIControlStateNormal];
        [self.buttonBeat2 setTitle:@"2" forState:UIControlStateNormal];
        [self.buttonBeat3 setTitle:@"3" forState:UIControlStateNormal];
        [self.buttonBeat4 setTitle:@"4" forState:UIControlStateNormal];
        
    } else if (self.viewDots.timeSignature == 1.4 || self.viewDots.timeSignature == 2.4 || self.viewDots.timeSignature == 3.4 || self.viewDots.timeSignature == 4.4) {
        self.buttonBeat3.hidden = NO;
        self.buttonBeat4.hidden = NO;
        
        //TODO: Add Images
        [self.buttonBeat1 setTitle:@"1" forState:UIControlStateNormal];
        [self.buttonBeat2 setTitle:@"2" forState:UIControlStateNormal];
        [self.buttonBeat3 setTitle:@"3" forState:UIControlStateNormal];
        [self.buttonBeat4 setTitle:@"4" forState:UIControlStateNormal];
        
    } else if (self.viewDots.timeSignature == 3.8 || self.viewDots.timeSignature == 6.8 || self.viewDots.timeSignature == 9.8 || self.viewDots.timeSignature == 12.8) {
        self.buttonBeat3.hidden = YES;
        self.buttonBeat4.hidden = YES;
        
        //TODO: Add Images
        [self.buttonBeat1 setTitle:@"1" forState:UIControlStateNormal];
        [self.buttonBeat2 setTitle:@"3" forState:UIControlStateNormal];
        
    }
}


@end
