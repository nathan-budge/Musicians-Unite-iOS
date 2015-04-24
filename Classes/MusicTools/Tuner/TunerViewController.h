//
//  TunerViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/8/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PitchDetector.h"

@interface TunerViewController : UIViewController <PitchDetectorDelegate>
{
    AudioController *audioManager;
    PitchDetector *autoCorrelator;
    NSMutableArray *medianPitchFollow;
}
@end
