//
//  AudioPlayer.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/24/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
// // Adapted from http://www.ymc.ch/en/building-a-simple-audioplayer-in-ios

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioPlayer : UIViewController

@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

- (void)initPlayer:(NSData*) audioData;
- (void)playAudio;
- (void)pauseAudio;
- (void)setCurrentAudioTime:(float)value;
- (float)getAudioDuration;
- (NSString*)timeFormat:(float)value;
- (NSTimeInterval)getCurrentAudioTime;

@end
