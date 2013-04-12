//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/12/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "TimeSeries.h"
@interface TimeSeries()
-(float)calculateStandardDeviation;
-(void)updateStandardDeviation: (float) y;
@property (nonatomic) float standardDeviationSquared;
@end

@implementation TimeSeries

@synthesize standardDeviation;
@synthesize x = _x;
@synthesize y = _y;
@synthesize min;
@synthesize max;
@synthesize count;
@synthesize standardDeviationSquared;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // insert initializing here
        self.count = 0;
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
-(void)addPoint: (float)y{
    //[self.x addObject:[NSNumber numberWithFloat:x]];
    [self.y addObject:[NSNumber numberWithFloat:y]];
    if ([self.y count] == 1) {
        self.max = y;
        self.min = y;
        self.standardDeviation = 0;
        self.standardDeviationSquared = 0;
        self.average = y;
    } else {
        self.average = 0.5 * (self.average + y);
        if (self.max < y){ self.max = y; }
        if (self.min > y){ self.min = y; }
        [self updateStandardDeviation:y];
        self.standardDeviation = sqrtf(self.standardDeviationSquared/[self.y count]);
    }
}

-(float)calculateStandardDeviation{
    float temp = 0;
    for (NSNumber *number in self.y) {
        temp += powf([number floatValue] - self.average, 2);
    }
    return sqrtf(temp/[self.y count]);
}

-(void)updateStandardDeviation: (float) newy{
    if ([self.y count] == 1) {
        self.standardDeviationSquared = powf([[self.y objectAtIndex:0] floatValue] - self.average, 2);
    } else {
        self.standardDeviationSquared += powf(newy - self.average, 2);
    }
}

@end
