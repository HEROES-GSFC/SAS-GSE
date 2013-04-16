//
//  PlotWindowController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/14/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>
#import "DataSeries.h"

@interface PlotWindowController : NSWindowController<CPTPlotDataSource> {
    CPTXYGraph *graph;
    NSArray *plotData;
}

@property (nonatomic, strong) IBOutlet CPTGraphHostingView *hostView;
@property (nonatomic, strong) DataSeries *x;
@property (nonatomic, strong) DataSeries *y;
@property (nonatomic) float test;

-(void) update;

@end
