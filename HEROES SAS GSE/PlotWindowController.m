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
@synthesize time = _time;
@synthesize y = _y;
@synthesize YmaxTextField;
@synthesize YminTextField;
@synthesize YminChoice;
@synthesize YmaxChoice;
@synthesize XaxisChoice;

-(CPTGraphHostingView *)hostView{
    if (_hostView == nil) {
        _hostView = [[CPTGraphHostingView alloc] init];
    }
    return _hostView;
}

- (IBAction)YminClicked:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [self.YminTextField setEnabled:NO];
    }
    if ([sender selectedSegment] == 1) {
        [self.YminTextField setEnabled:YES];
    }
    [self update];
}

- (IBAction)YmaxClicked:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [self.YmaxTextField setEnabled:NO];
    }
    if ([sender selectedSegment] == 1) {
        [self.YmaxTextField setEnabled:YES];
    }
    [self update];
}

- (IBAction)XaxisClicked:(NSSegmentedControl *)sender {
    [self update];
}

- (id)init{
    return [super initWithWindowNibName:@"PlotWindowController"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        //insert initialization here
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if (self.y == nil) {
        NSMutableArray *tempx = [[NSMutableArray alloc] init];
        DataSeries *tempy = [[DataSeries alloc] init];
        tempy.name = @"temp data";
        for (int i = 0; i < 100; i++) {
            [tempx addObject:[[NSDate date] dateByAddingTimeInterval:i]];
            [tempy addPoint:15+(float)arc4random()/RAND_MAX];
        }
        self.time = tempx;
        self.y = tempy;
    }
    // If you make sure your dates are calculated at noon, you shouldn't have to
    // worry about daylight savings. If you use midnight, you will have to adjust
    // for daylight savings time.
    
    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graph.plotAreaFrame.paddingTop    = 15.0;
    graph.plotAreaFrame.paddingRight  = 15.0;
    graph.plotAreaFrame.paddingBottom = 55.0;
    graph.plotAreaFrame.paddingLeft   = 55.0;
    
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:theme];
    graph.plotAreaFrame.borderLineStyle = nil;
    
    self.hostView.hostedGraph = graph;
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.5f;
    majorGridLineStyle.lineColor = [CPTColor grayColor];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    
    // X axes
    CPTXYAxis *x = axisSet.xAxis;
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.majorIntervalLength = CPTDecimalFromFloat(10);        // one minute
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval       = 5;                      // one every ten s
    
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    x.majorGridLineStyle = majorGridLineStyle;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
    y.title = self.y.name;
    y.majorGridLineStyle = majorGridLineStyle;
    
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier = @"Time Plot";
    
    // linestyle for data
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 2.f;
    lineStyle.lineColor              = [CPTColor redColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];
    [self update];
}
#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return plotData.count;
}

- (IBAction)TextFieldUpdated:(NSTextField *)sender {
    [self update];
}

-(void)update{
    NSDate *latestTime = [self.time objectAtIndex:[self.time count]-1];
    NSDate *earliestTime;
    float ymin, ymax;
    
    if (self.XaxisChoice.selectedSegment == 0) {
        earliestTime = [self.time objectAtIndex:0];}
    else { earliestTime = [self.time objectAtIndex:self.y.ROI.location]; }
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.hostView.hostedGraph.axisSet;
    
    // should calculate the size of major and minor tickintevals needed on the fly
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPTDecimalFromString(@"1");
    y.minorTicksPerInterval = 10;
    
    // X axes
    CPTXYAxis *x = axisSet.xAxis;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate = earliestTime;
    x.labelFormatter = timeFormatter;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.hostView.hostedGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                    length:CPTDecimalFromFloat([latestTime timeIntervalSinceDate:earliestTime])];
    
    if (self.YminChoice.selectedSegment == 0) {
        ymin = self.y.min;
    } else { ymin = [self.YminTextField floatValue]; }
    if (self.YmaxChoice.selectedSegment == 0) {
        ymax = self.y.max;
    } else { ymax = [self.YmaxTextField floatValue]; }
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(ymin) length:CPTDecimalFromFloat(ymax-ymin)];
    
    NSUInteger indexmin = self.XaxisChoice.selectedSegment == 0 ? 0 : self.y.ROI.location;
    NSMutableArray *data = [NSMutableArray array];
    for ( NSUInteger i = indexmin; i < [self.time count]-1; i++ ) {
        NSTimeInterval x = [[self.time objectAtIndex:i] timeIntervalSinceDate:earliestTime];
        [data addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX],
          [self.y.data objectAtIndex:i], [NSNumber numberWithInt:CPTScatterPlotFieldY],
          nil]];
    }
    plotData = data;
    [graph reloadData];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [[plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];
    
    return num;
}

@end
