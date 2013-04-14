//
//  PlotWindowController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/14/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@interface PlotWindowController : NSWindowController<CPTPlotDataSource> {
    CPTXYGraph *graph;
    NSArray *plotData;
}

@property (nonatomic, strong) IBOutlet CPTGraphHostingView *hostView;

@end
