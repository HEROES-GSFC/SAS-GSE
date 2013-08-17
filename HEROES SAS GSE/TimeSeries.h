//
//  TimeSeries.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 8/15/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "DataSeries.h"

@interface TimeSeries : DataSeries

@property (nonatomic, strong) NSMutableArray *time;
@property (nonatomic) BOOL ROIEnabled;

- (void) addPointWithTime: (NSDate *) time :(float)newpoint;
- (NSDate *) earliestTime;
- (NSDate *) latestTime;
- (NSArray *) time;

@end
