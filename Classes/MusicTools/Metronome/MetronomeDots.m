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
        
        [[UIColor blackColor] setStroke];
        [[UIColor grayColor] setFill];
        
        [shape fill];
        
        /*
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 8, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 12, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 8, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
    
    } else if (self.timeSignature == 2.2 || self.timeSignature == 2.4) {
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 100, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 50, 25, 50, 50)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 85, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 65, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 85, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 65, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 85, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 65, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
    
    } else if (self.timeSignature == 3.2 || self.timeSignature == 3.4) {
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 125, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 25, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 75, 25, 50, 50)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 110, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 90, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 110, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 10, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 10, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 10, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 90, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 110, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 90, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
        
    } else if (self.timeSignature == 4.2 || self.timeSignature == 4.4) {
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 140, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 65, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 10, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 85, 25, 50, 50)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 125, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 105, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 125, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 50, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 30, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 50, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 25, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 45, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 25, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 100, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 120, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 100, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        */
         
    } else if (self.timeSignature == 3.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 75, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2, 35, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 50, 35, 30, 30)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 60, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 40, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 60, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
        
        
    } else if (self.timeSignature == 6.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 35, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 35, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 25, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 35, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 35, 30, 30)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 155, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 135, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 155, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 30, 40)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 50, 50)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 30, 60)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
        
        
    } else if (self.timeSignature == 9.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 75, 5, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2, 15, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 50, 15, 30, 30)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 60, 20)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 40, 30)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 60, 40)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
        
        
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 65, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 75, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 75, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 65, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 75, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 75, 30, 30)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 155, 80)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 135, 90)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 155, 100)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 30, 80)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 50, 90)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 30, 100)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
        
        
    } else if (self.timeSignature == 12.8) {
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 5, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 15, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 15, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 5, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 15, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 15, 30, 30)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 155, 20)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 135, 30)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 155, 40)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 30, 20)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 50, 30)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 30, 40)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
        
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 150, 65, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 85, 75, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 - 40, 75, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 15, 65, 50, 50)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 80, 75, 30, 30)];
        
        [shape fill];
        
        shape = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2 + 125, 75, 30, 30)];
        
        [shape fill];
        
        /*
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 - 155, 80)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 135, 90)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 - 155, 100)];
        path.lineWidth = 2.5f;
        [path stroke];
        
        path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.bounds.size.width/2 + 30, 80)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 50, 90)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width/2 + 30, 100)];
        path.lineWidth = 2.5f;
        [path stroke];
         */
    }
    
}


@end
