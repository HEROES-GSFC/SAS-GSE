//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 8/15/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "DataSeries.h"
#import "TimeSeries.h"

@implementation TimeSeries

- (void) addPointWithTime: (NSDate *) time :(float)newpoint{
    [self.data addObject:[NSNumber numberWithFloat:newpoint]];
    [self.time addObject:time];
    [self update];
}

@end
