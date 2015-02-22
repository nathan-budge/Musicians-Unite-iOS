//
//  CircularButton.m
//  Musicians-Unite-iOS
//
//  Created by Jack Ramsey on 2/21/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
// Adapted from a project found at https://github.com/elpsk/APRoundedButton
//

#import "CircularButton.h"

@implementation CircularButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    
    CGFloat radius;
    if (width < height) {
        radius = width / 2;
    } else {
        radius = height / 2;
    }
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width / 2, height / 2) radius:radius startAngle:0 endAngle:360 clockwise:YES];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame         = self.bounds;
    maskLayer.path          = maskPath.CGPath;
    self.layer.mask         = maskLayer;
}

@end
