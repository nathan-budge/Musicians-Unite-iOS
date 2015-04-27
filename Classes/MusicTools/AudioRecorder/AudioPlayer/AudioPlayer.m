//
//  AudioPlayer.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/24/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
// Adapted from http://www.ymc.ch/en/building-a-simple-audioplayer-in-ios

#import "AudioPlayer.h"

@implementation AudioPlayer

- (void)initPlayer:(NSData *) audioData
{
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil];
}


- (void)playAudio {
    [self.audioPlayer play];
}


- (void)pauseAudio {
    [self.audioPlayer pause];
}


-(NSString*)timeFormat:(float)value{
    
    float minutes = floor(lroundf(value)/60);
    float seconds = lroundf(value) - (minutes * 60);
    
    int roundedSeconds = (int)lroundf(seconds);
    int roundedMinutes = (int)lroundf(minutes);
    
    NSString *time = [[NSString alloc]
                      initWithFormat:@"%d:%02d",
                      roundedMinutes, roundedSeconds];
    return time;
}


- (void)setCurrentAudioTime:(float)value {
    [self.audioPlayer setCurrentTime:value];
}


- (NSTimeInterval)getCurrentAudioTime {
    return [self.audioPlayer currentTime];
}


- (float)getAudioDuration {
    return [self.audioPlayer duration];
}

@end
