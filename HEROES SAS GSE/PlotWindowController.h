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
@property (nonatomic, strong) NSMutableArray *time;
@property (nonatomic, strong) DataSeries *y;
- (IBAction)YminClicked:(NSSegmentedControl *)sender;
- (IBAction)YmaxClicked:(NSSegmentedControl *)sender;
- (IBAction)XaxisClicked:(NSSegmentedControl *)sender;
@property (weak) IBOutlet NSTextField *YminTextField;
@property (weak) IBOutlet NSTextField *YmaxTextField;
@property (weak) IBOutlet NSSegmentedControl *YminChoice;
@property (weak) IBOutlet NSSegmentedControl *YmaxChoice;
@property (weak) IBOutlet NSSegmentedControl *XaxisChoice;
- (IBAction)TextFieldUpdated:(NSTextField *)sender;

-(void) update;

@end
