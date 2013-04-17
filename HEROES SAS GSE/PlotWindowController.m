//
//  PlotWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/14/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "PlotWindowController.h"
#import <CorePlot/CorePlot.h>

@interface PlotWindowController ()
@end

@implementation PlotWindowController

@synthesize hostView = _hostView;
@synthesize x = _x;
@synthesize y = _y;

-(DataSeries *)x{
    if (_x == nil) {
        _x = [[DataSeries alloc]init];
    }
    return _x;
}

-(DataSeries *)y{
    if (_y == nil) {
        _y = [[DataSeries alloc]init];
    }
    return _y;
}

-(CPTGraphHostingView *)hostView{
    if (_hostView == nil) {
        _hostView = [[CPTGraphHostingView alloc] init];
    }
    return _hostView;
}

- (id)init{
    return [super initWithWindowNibName:@"PlotWindowController"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.test = 5;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // If you make sure your dates are calculated at noon, you shouldn't have to
    // worry about daylight savings. If you use midnight, you will have to adjust
    // for daylight savings time.
    NSDate *refDate       = [NSDate dateWithNaturalLanguageString:@"12:00 Oct 29, 2009"];
    NSTimeInterval oneDay = 24 * 60 * 60;
    
    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainBlackTheme];
    [graph applyTheme:theme];
    self.hostView.hostedGraph = graph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    NSTimeInterval xLow       = 0.0f;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xLow) length:CPTDecimalFromFloat(oneDay * 5.0f + self.test)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(3.0)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromFloat(oneDay);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval       = 0;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterShortStyle];
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate = refDate;
    x.labelFormatter            = timeFormatter;
    x.title = @"Temperature";
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromString(@"0.5");
    y.minorTicksPerInterval       = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(oneDay);
    
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier = @"Date Plot";
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 3.f;
    lineStyle.lineColor              = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];
    
    // Add some data
    NSMutableArray *newData = [NSMutableArray array];
    for ( NSUInteger i = 0; i < 5; i++ ) {
        NSTimeInterval x = oneDay * i;
        id y             = [NSDecimalNumber numberWithFloat:1.2 * rand() / (float)RAND_MAX + 1.2];
        [newData addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSDecimalNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX],
          y, [NSNumber numberWithInt:CPTScatterPlotFieldY],
          nil]];
    }
    plotData = newData;
    
    // Link data in

}
#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return plotData.count;
}

-(void)update{
    NSTimeInterval oneDay = 24 * 60 * 60;

    [self.x addPoint:[self.x.data count]+1];
    
    NSMutableArray *data = [NSMutableArray array];
    for (int i = 0; i < self.x.max; i++) {
        [data addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                          [self.x.data objectAtIndex:i], [NSNumber numberWithInt:CPTScatterPlotFieldX],
                          [self.y.data objectAtIndex:i], [NSNumber numberWithInt:CPTScatterPlotFieldY],
                          nil]];
    }
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0) length:CPTDecimalFromFloat([self.x.data count])];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(100)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromString(@"5");
    y.minorTicksPerInterval       = 10;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(oneDay);
    
    plotData = data;
    [graph reloadData];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [[plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];
    
    return num;
}

@end
