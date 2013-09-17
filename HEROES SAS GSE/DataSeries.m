//
//  TimeSeries.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/12/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "DataSeries.h"

#define MAX_CAPACITY 50

@interface DataSeries()
-(float)calculateAverage;
-(float)calculateStandardDeviation;
@property (nonatomic, strong) NSMutableArray *mydata;
@property (nonatomic) NSUInteger count;
@end

@implementation DataSeries

@synthesize standardDeviation;
@synthesize min;
@synthesize max;
@synthesize count;
@synthesize average;
@synthesize ROI;
@synthesize description;
@synthesize name;
@synthesize ROIlength;
@synthesize ROIEnabled;
@synthesize mydata = _mydata;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // insert initializing here
        self.count = 0;
        self.ROIlength = 10;
        self.ROI = NSMakeRange(0, self.ROIlength);
        self.ROIEnabled = NO;
    }
    return self;
}

-(NSMutableArray *)mydata{
    if (_mydata == nil) {
        _mydata = [[NSMutableArray alloc] initWithCapacity:MAX_CAPACITY];
    }
    return _mydata;
}

-(NSArray *) data{
    if (self.ROIEnabled) {
        return [self.mydata subarrayWithRange:self.ROI];
    } else {
        return [NSArray arrayWithArray:self.mydata];
    }
}

- (void) addPoint: (float)newpoint{
    [self.mydata addObject:[NSNumber numberWithFloat:newpoint]];
    if ([self.mydata count] == MAX_CAPACITY) {
        [self.mydata removeObjectAtIndex:0];
    }
    [self update];
}

- (void) update{
    float latest_value = [self.mydata.lastObject floatValue];
    self.count = [[self data] count];
    if (self.count == 1){
        self.max = latest_value;
        self.min = latest_value;
    } else {
        if (self.max < latest_value){ self.max = latest_value; }
        if (self.min > latest_value){ self.min = latest_value; }
    }
    self.average = [self calculateAverage];
    self.standardDeviation = [self calculateStandardDeviation];
    NSInteger location = self.count - self.ROIlength - 1;
    if (location < 0) {
        location = 0;
    } else {
        location = self.count - self.ROIlength - 1;
    }
    NSUInteger length;
    if (self.ROIlength > self.count){
        length = self.count;
    } else {
        length = self.ROIlength;
    }
    self.ROI = NSMakeRange(location, length);
}

- (float) calculateAverage{
    NSArray *Array = [self data];
    float answer = 0;
    for (NSNumber *number in Array) {
        answer += [number floatValue];
    }
    return answer/[Array count];
}

- (float) calculateStandardDeviation{
    NSArray *Array = [self data];
    float answer = 0;
    float localAverage = self.average;
    for (NSNumber *number in Array) {
        answer += powf([number floatValue] - localAverage, 2);
    }
    return sqrtf(answer/[Array count]);
}

@end