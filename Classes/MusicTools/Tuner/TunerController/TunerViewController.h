//
//  TunerViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/8/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Recorder.h"

@interface TunerViewController : UIViewController <RecorderDelegate>
{
    Recorder* recorder;
    
    float detectedFreq;           // the frequency we detected
    float deltaFreq;              // for calculating how sharp/flat user is
}

- (void)beginInterruption;
- (void)endInterruption;
@end
