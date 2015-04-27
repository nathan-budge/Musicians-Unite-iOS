//
//  RecorderViewController.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class Group;

@interface RecorderViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>

@property (nonatomic) Group *group;

@end
