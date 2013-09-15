//
//  TimeSeries.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/12/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataSeries : NSObject

@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) float standardDeviation;
@property (nonatomic) float average;
@property (nonatomic) float max;
@property (nonatomic) float min;
@property (nonatomic) NSRange ROI;
@property (nonatomic) int ROIlength;
@property (nonatomic) BOOL ROIEnabled;

- (void) addPoint: (float) point;
- (void) update;
- (NSArray *) data;

@end
