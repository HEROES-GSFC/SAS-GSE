//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 8/15/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "DataSeries.h"
#import "TimeSeries.h"

#define MAX_CAPACITY 1000

@interface TimeSeries()
@property (nonatomic, strong) NSMutableArray *mytime;
@end

@implementation TimeSeries

@synthesize mytime = _mytime;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // insert initializing here
    }
    return self;
}

-(NSMutableArray *)mytime{
    if (_mytime == nil) {
        _mytime = [[NSMutableArray alloc] initWithCapacity:MAX_CAPACITY];
    }
    return _mytime;
}

- (void) addPointWithTime: (NSDate *) newTime :(float)newPoint{
    [self addPoint:newPoint];
    [self.mytime addObject:newTime];
    if ([self.mytime count] == MAX_CAPACITY) {
        [self.mytime removeObjectAtIndex:0];
    }
    [self update];
}

- (NSDate *) earliestTime{
    return [[self time] objectAtIndex:0];
}

- (NSDate *) latestTime{
    return [[self time] lastObject];
}

- (NSArray *) time{
    if (self.ROIEnabled) {
        return [self.mytime subarrayWithRange:self.ROI];
    } else {
        return [NSArray arrayWithArray:self.mytime];
    }
}



@end
