//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 8/15/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "DataSeries.h"
#import "TimeSeries.h"

@interface TimeSeries()
@property (nonatomic, strong) NSMutableArray *mytime;
@end

@implementation TimeSeries

@synthesize mytime = _mytime;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // insert initializing here
        self.count = 0;
        self.ROIlength = 1;
        self.ROI = NSMakeRange(0, self.ROIlength);
        if (_mytime == nil) {
            _mytime = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (void) addPointWithTime: (NSDate *) time :(float)newpoint{
    [self addPoint:newpoint];
    [self.mytime addObject:time];
    [self update];
}

- (NSDate *)earliestTime{
    if (self.ROIEnabled) {
        return [[self.time subarrayWithRange:self.ROI] objectAtIndex:0];
    } else {
        return [self.time objectAtIndex:0];
    }
}

- (NSDate *)latestTime{
    if (self.ROIEnabled) {
        return [[self.time subarrayWithRange:self.ROI] lastObject];
    } else {
        return [self.time lastObject];
    }
}

- (NSArray *) time{
    if (self.ROIEnabled) {
        return [self.mytime subarrayWithRange:self.ROI];
    } else {
        return [NSArray arrayWithArray:self.mytime];
    }
}



@end
