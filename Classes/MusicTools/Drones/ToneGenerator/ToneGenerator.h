//
//  ToneGenerator.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/28/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from https://github.com/MMercieca/Handshake/blob/master/Handshake/ToneGenerator.h
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ToneGenerator : NSObject

@property (nonatomic) AudioComponentInstance toneUnit;
@property (nonatomic) double frequency;

-(ToneGenerator*)init;

-(void)play;
-(void)stop;

@end
