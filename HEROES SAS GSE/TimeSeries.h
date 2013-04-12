//
//  TimeSeries.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/12/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeSeries : NSObject

@property (nonatomic, strong) NSMutableArray *x;
@property (nonatomic, strong) NSMutableArray *y;
@property (nonatomic) float standardDeviation;
@property (nonatomic) float average;
@property (nonatomic) float max;
@property (nonatomic) float min;
@property (nonatomic) float count;

- (void) addPoint: (float)y;


@end
