//
//  FaceView.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 4/8/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FaceView;

@protocol FaceViewDataSource
- (float)smileForFaceView: (FaceView *)sender;
@end

@interface FaceView : UIView

@property (nonatomic, weak) IBOutlet id <FaceViewDataSource> dataSource;

@end
