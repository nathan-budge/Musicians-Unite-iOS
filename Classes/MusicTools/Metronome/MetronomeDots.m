//
//  MetronomeDots.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/31/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "MetronomeDots.h"

@implementation MetronomeDots

- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] setStroke];
    [[UIColor grayColor] setFill];
    UIBezierPath *shape;
    //UIBezierPath *path;
    
    if (self.timeSignature == 1.4) {
        UIBezierPath *shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 25, 25, 50, 50)];

        [self checkBeatAndFill:1 withShape:shape];
    
    } else if (self.timeSignature == 2.2 || self.timeSignature == 2.4) {
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 100, 25, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 50, 25, 50, 50)];
        
        [self checkBeatAndFill:2 withShape:shape];
    
    } else if (self.timeSignature == 3.2 || self.timeSignature == 3.4) {
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 125, 25, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 75, 25, 50, 50)];
        
        [self checkBeatAndFill:2 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 25, 25, 50, 50)];
        
        [self checkBeatAndFill:3 withShape:shape];
        
    } else if (self.timeSignature == 4.2 || self.timeSignature == 4.4) {
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 140, 25, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 65, 25, 50, 50)];
        
        [self checkBeatAndFill:2 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 10, 25, 50, 50)];
        
        [self checkBeatAndFill:3 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 85, 25, 50, 50)];
        
        [self checkBeatAndFill:4 withShape:shape];
         
    } else if (self.timeSignature == 3.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 75, 25, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2, 35, 30, 30)];
        
        [self checkBeatAndFill:2 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 50, 35, 30, 30)];
        
        [self checkBeatAndFill:3 withShape:shape];
        
    } else if (self.timeSignature == 6.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 25, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 35, 30, 30)];
        
        [self checkBeatAndFill:2 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 35, 30, 30)];
        
        [self checkBeatAndFill:3 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 25, 50, 50)];
        
        [self checkBeatAndFill:4 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 35, 30, 30)];
        
        [self checkBeatAndFill:5 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 35, 30, 30)];
        
        [self checkBeatAndFill:6 withShape:shape];
        
    } else if (self.timeSignature == 9.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 75, 5, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2, 15, 30, 30)];
        
        [self checkBeatAndFill:2 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 50, 15, 30, 30)];
        
        [self checkBeatAndFill:3 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 65, 50, 50)];
        
        [self checkBeatAndFill:4 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 75, 30, 30)];
        
        [self checkBeatAndFill:5 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 75, 30, 30)];
        
        [self checkBeatAndFill:6 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 65, 50, 50)];
        
        [self checkBeatAndFill:7 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 75, 30, 30)];
        
        [self checkBeatAndFill:8 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 75, 30, 30)];
        
        [self checkBeatAndFill:9 withShape:shape];
        
        
    } else if (self.timeSignature == 12.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 5, 50, 50)];
        
        [self checkBeatAndFill:1 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 15, 30, 30)];
        
        [self checkBeatAndFill:2 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 15, 30, 30)];
        
        [self checkBeatAndFill:3 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 5, 50, 50)];
        
        [self checkBeatAndFill:4 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 15, 30, 30)];
        
        [self checkBeatAndFill:5 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 15, 30, 30)];
        
        [self checkBeatAndFill:6 withShape:shape];
        
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 65, 50, 50)];
        
        [self checkBeatAndFill:7 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 75, 30, 30)];
        
        [self checkBeatAndFill:8 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 75, 30, 30)];
        
        [self checkBeatAndFill:9 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 65, 50, 50)];
        
        [self checkBeatAndFill:10 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 75, 30, 30)];
        
        [self checkBeatAndFill:11 withShape:shape];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 75, 30, 30)];
        
        [self checkBeatAndFill:12 withShape:shape];
    }
    
}

-(void)checkBeatAndFill:(int)beatNumber withShape:(UIBezierPath*)shape {
    if (self.highlightedBeat == beatNumber) {
        [[UIColor redColor] setFill];
    }
    
    [shape fill];
    [[UIColor blackColor] setStroke];
    [[UIColor grayColor] setFill];
}


@end
