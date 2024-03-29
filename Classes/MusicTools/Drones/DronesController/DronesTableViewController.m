//
//  DronesTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/28/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "DronesTableViewController.h"
#import "ToneGenerator.h"
#import "AppConstant.h"


@interface DronesTableViewController ()

@property (nonatomic) ToneGenerator *toneGenerator;

@property (nonatomic) UIButton *selectedButton;

@property (weak, nonatomic) IBOutlet UIButton *buttonPlay;

@property (weak, nonatomic) IBOutlet UILabel *labelOctave;
@property (weak, nonatomic) IBOutlet UIStepper *octaveStepper;

@property (weak, nonatomic) IBOutlet UIButton *buttonC;
@property (weak, nonatomic) IBOutlet UIButton *buttonG;
@property (weak, nonatomic) IBOutlet UIButton *buttonD;
@property (weak, nonatomic) IBOutlet UIButton *buttonA;
@property (weak, nonatomic) IBOutlet UIButton *buttonE;
@property (weak, nonatomic) IBOutlet UIButton *buttonB;
@property (weak, nonatomic) IBOutlet UIButton *buttonGb;
@property (weak, nonatomic) IBOutlet UIButton *buttonDb;
@property (weak, nonatomic) IBOutlet UIButton *buttonAb;
@property (weak, nonatomic) IBOutlet UIButton *buttonEb;
@property (weak, nonatomic) IBOutlet UIButton *buttonBb;
@property (weak, nonatomic) IBOutlet UIButton *buttonF;

@end


@implementation DronesTableViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

-(ToneGenerator *)toneGenerator
{
    if (!_toneGenerator) {
        _toneGenerator = [[ToneGenerator alloc] init];
    }
    return _toneGenerator;
}


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.octaveStepper.value = 4.0;
    self.labelOctave.text = [NSString stringWithFormat:@"%.f",self.octaveStepper.value];
    
    self.buttonA.selected = YES;
    self.selectedButton = self.buttonA;
    [self.selectedButton sendActionsForControlEvents: UIControlEventTouchUpInside];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.title = @"Drones";
}


//*****************************************************************************/
#pragma mark - Drone Buttons
//*****************************************************************************/

- (IBAction)actionC:(id)sender
{
    double frequency = FREQ_C0;
    [self selectButton:self.buttonC withFrequency:frequency];
}

- (IBAction)actionG:(id)sender
{
    double frequency = FREQ_G0;
    [self selectButton:self.buttonG withFrequency:frequency];
}

- (IBAction)actionD:(id)sender
{
    double frequency = FREQ_D0;
    [self selectButton:self.buttonD withFrequency:frequency];
}

- (IBAction)actionA:(id)sender
{
    double frequency = FREQ_A0;
    [self selectButton:self.buttonA withFrequency:frequency];
}

- (IBAction)actionE:(id)sender
{
    double frequency = FREQ_E0;
    [self selectButton:self.buttonE withFrequency:frequency];
}

- (IBAction)actionB:(id)sender
{
    double frequency = FREQ_B0;
    [self selectButton:self.buttonB withFrequency:frequency];
}

- (IBAction)actionGb:(id)sender
{
    double frequency = FREQ_GB0;
    [self selectButton:self.buttonGb withFrequency:frequency];
}

- (IBAction)actionDb:(id)sender
{
    double frequency = FREQ_DB0;
    [self selectButton:self.buttonDb withFrequency:frequency];
}

- (IBAction)actionAb:(id)sender
{
    double frequency = FREQ_AB0;
    [self selectButton:self.buttonAb withFrequency:frequency];
}

- (IBAction)actionEb:(id)sender
{
    double frequency = FREQ_EB0;
    [self selectButton:self.buttonEb withFrequency:frequency];
}

- (IBAction)actionBb:(id)sender
{
    double frequency = FREQ_BB0;
    [self selectButton:self.buttonBb withFrequency:frequency];
}

- (IBAction)actionF:(id)sender
{
    double frequency = FREQ_F0;
    [self selectButton:self.buttonF withFrequency:frequency];
}


//*****************************************************************************/
#pragma mark - Octave Stepper
//*****************************************************************************/

- (IBAction)actionChangeOctave:(id)sender
{
    self.labelOctave.text = [NSString stringWithFormat:@"%.f",self.octaveStepper.value];
    [self.selectedButton sendActionsForControlEvents: UIControlEventTouchUpInside];
}


//*****************************************************************************/
#pragma mark - Play Button
//*****************************************************************************/

- (IBAction)actionPlay:(id)sender
{
    self.toneGenerator.toneUnit ? [self stop] : [self play];
}


- (void)play
{
    [self.toneGenerator play];
    [self.buttonPlay setBackgroundImage:[UIImage imageNamed:@"button_stop"] forState:UIControlStateNormal];
}

- (void)stop
{
    [self.toneGenerator stop];
    [self.selectedButton sendActionsForControlEvents: UIControlEventTouchUpInside];
    [self.buttonPlay setBackgroundImage:[UIImage imageNamed:@"button_play"] forState:UIControlStateNormal];
}

//*****************************************************************************/
#pragma mark - Helper Methods
//*****************************************************************************/

- (void)selectButton:(UIButton *)button withFrequency:(const double)frequency
{
    self.selectedButton.selected = NO;
    self.selectedButton = button;
    button.selected = YES;
    self.toneGenerator.frequency = frequency;
    [self changePitch];
}

- (void)changePitch
{
    self.toneGenerator.frequency *= pow(2, self.octaveStepper.value);
}

@end
