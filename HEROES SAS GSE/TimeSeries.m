//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/12/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "TimeSeries.h"
@interface TimeSeries()
-(float)calculateStandardDeviation: (NSRange) range;
@end

@implementation TimeSeries

@synthesize standardDeviation;
@synthesize x = _x;
@synthesize y = _y;
@synthesize min;
@synthesize max;
@synthesize count;
@synthesize average;
@synthesize ROI;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // insert initializing here
        self.count = 0;
        self.ROI = NSMakeRange(0, 50);
    }
    return self;
}

-(NSMutableArray *) x{
    if (_x == nil) {
        _x = [[NSMutableArray alloc] init];
    }
    return _x;
}
-(NSMutableArray *) y{
    if (_y == nil) {
        _y = [[NSMutableArray alloc] init];
    }
    return _y;
}
- (void) addPoint: (float)x :(float) y{
    [self.x addObject:[NSNumber numberWithFloat:x]];
    [self.y addObject:[NSNumber numberWithFloat:y]];
    if ([self.y count] == 1) {
        self.max = y;
        self.min = y;
        self.average = y;
    } else {
        if (self.max < y){ self.max = y; }
        if (self.min > y){ self.min = y; }
    }
}

-(float)average{
    NSArray *ROIArray = [self.y subarrayWithRange:self.ROI];
    float answer = 0;
    for (NSNumber *number in ROIArray) {
        answer += [number floatValue];
    }
    return answer/[ROIArray count];
}

-(float)standardDeviation{
    NSArray *ROIArray = [self.y subarrayWithRange:self.ROI];
    float answer = 0;
    float localAverage = self.average;
    for (NSNumber *number in ROIArray) {
        answer += powf([number floatValue] - localAverage, 2);
    }
    return sqrtf(answer/[ROIArray count]);
}

@end
