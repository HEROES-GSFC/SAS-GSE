//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/12/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "DataSeries.h"

@implementation DataSeries

@synthesize standardDeviation;
@synthesize data = _data;
@synthesize min;
@synthesize max;
@synthesize count;
@synthesize average;
@synthesize ROI;
@synthesize description;
@synthesize name;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // insert initializing here
        self.count = 0;
        self.ROI = NSMakeRange(0, 50);
    }
    return self;
}

-(NSMutableArray *) data{
    if (_data == nil) {
        _data = [[NSMutableArray alloc] init];
    }
    return _data;
}
- (void) addPoint: (float)newpoint{
    [self.data addObject:[NSNumber numberWithFloat:newpoint]];
    self.count++;
    if (self.count == 1) {
        self.max = newpoint;
        self.min = newpoint;
    } else {
        if (self.max < newpoint){ self.max = newpoint; }
        if (self.min > newpoint){ self.min = newpoint; }
    }
    if (self.count > self.ROI.length) {
        self.ROI = NSMakeRange(self.ROI.location + self.count - self.ROI.length, self.ROI.length);
    }
}

-(float)average{
    NSArray *ROIArray = [self.data subarrayWithRange:self.ROI];
    float answer = 0;
    for (NSNumber *number in ROIArray) {
        answer += [number floatValue];
    }
    return answer/[ROIArray count];
}

-(float)standardDeviation{
    NSArray *ROIArray = [self.data subarrayWithRange:self.ROI];
    float answer = 0;
    float localAverage = self.average;
    for (NSNumber *number in ROIArray) {
        answer += powf([number floatValue] - localAverage, 2);
    }
    return sqrtf(answer/[ROIArray count]);
}

@end