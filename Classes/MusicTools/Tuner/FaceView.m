//
//  FaceView.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/8/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from Happiness L6 http://web.stanford.edu/class/cs193p/cgi-bin/drupal/

#import "FaceView.h"


@interface FaceView ()

@property (nonatomic) CGFloat faceRadius;
@property (nonatomic) CGPoint faceCenter;

@end


@implementation FaceView

#define SCALE 0.8
#define LINE_WIDTH 3
#define FACE_RADIUS_TO_EYE_RADIUS_RATIO 10
#define FACE_RADIUS_TO_EYE_OFFSET_RATIO 3
#define FACE_RADIUS_TO_EYE_SEPARATION_RATIO 1.5
#define FACE_RADIUS_TO_MOUTH_WIDTH_RATIO 1
#define FACE_RADIUS_TO_MOUTH_HEIGHT_RATIO 3
#define FACE_RADIUS_TO_MOUTH_OFFSET_RATIO 3

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.contentMode = UIViewContentModeRedraw;
}

- (void)drawRect:(CGRect)rect
{
    double smiliness = self.dataSource ? [self.dataSource smileForFaceView:self] : 0.0;
    
    CGFloat red = 255;
    CGFloat green = 255;
    
    if (smiliness >  0)
    {
        green *= smiliness;
        red *= 1 - smiliness;
    }
    else if (smiliness < 0)
    {
        red *= fabsf(smiliness);
        green *= 1 - fabsf(smiliness);
    }

    [[UIColor colorWithRed:red green:green blue:0 alpha:1] setFill];
    [[UIColor blackColor] setStroke];

    //draw face
    [[self bezierPathForFace] stroke];
    [[self bezierPathForFace] fill];
    
    //draw eyes
    [[self bezierPathForEye:true] stroke];
    [[self bezierPathForEye:false] stroke];
    
    //draw smile
    [[self bezierPathForSmile:smiliness] stroke];
}

- (UIBezierPath *)bezierPathForFace
{
    CGPoint midPoint;
    midPoint.x = self.bounds.origin.x + self.bounds.size.width/2;
    midPoint.y = self.bounds.origin.y + self.bounds.size.height/2;
    
    self.faceCenter = midPoint;
    
    self.faceRadius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 * SCALE;
    
    UIBezierPath *facePath = [UIBezierPath bezierPathWithArcCenter:self.faceCenter radius:self.faceRadius startAngle:0 endAngle:2*M_PI clockwise:true];
    
    facePath.lineWidth = LINE_WIDTH;
    
    return facePath;
}

- (UIBezierPath *)bezierPathForEye:(BOOL) leftEye
{
    CGFloat eyeRadius = self.faceRadius / FACE_RADIUS_TO_EYE_RADIUS_RATIO;
    CGFloat eyeVerticalOffset = self.faceRadius / FACE_RADIUS_TO_EYE_OFFSET_RATIO;
    CGFloat eyeHorizontalSeparation = self.faceRadius / FACE_RADIUS_TO_EYE_SEPARATION_RATIO;
    
    CGPoint eyeCenter = self.faceCenter;
    eyeCenter.y -= eyeVerticalOffset;
    
    if (leftEye)
    {
        eyeCenter.x -= eyeHorizontalSeparation / 2;
    }
    else
    {
        eyeCenter.x += eyeHorizontalSeparation / 2;
    }
    
    UIBezierPath *eyeballPath = [UIBezierPath bezierPathWithArcCenter:eyeCenter radius:eyeRadius startAngle:0 endAngle:2*M_PI clockwise:true];
    eyeballPath.lineWidth = LINE_WIDTH;
    
    return eyeballPath;
}

- (UIBezierPath *)bezierPathForSmile: (double) fractionOfMaxSmile
{
    CGFloat mouthWidth = self.faceRadius / FACE_RADIUS_TO_MOUTH_WIDTH_RATIO;
    CGFloat mouthHeight = self.faceRadius / FACE_RADIUS_TO_MOUTH_HEIGHT_RATIO;
    CGFloat mouthVerticalOffset = self.faceRadius / FACE_RADIUS_TO_MOUTH_OFFSET_RATIO;
    
    CGFloat smileHeight = MAX(MIN(fractionOfMaxSmile, 1), -1) * mouthHeight;
    
    CGPoint start = CGPointMake(self.faceCenter.x - mouthWidth / 2, self.faceCenter.y + mouthVerticalOffset);
    CGPoint end = CGPointMake(start.x + mouthWidth, start.y);
    CGPoint cp1 = CGPointMake(start.x + mouthWidth / 3, start.y + smileHeight);
    CGPoint cp2 = CGPointMake(end.x - mouthWidth / 3, cp1.y);
    
    UIBezierPath *smilePath = [UIBezierPath bezierPath];
    [smilePath moveToPoint:start];
    [smilePath addCurveToPoint:end controlPoint1:cp1 controlPoint2:cp2];
    smilePath.lineWidth = LINE_WIDTH;
    
    return smilePath;
}


@end
