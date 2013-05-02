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
    
    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graph.plotAreaFrame.paddingTop    = 15.0;
    graph.plotAreaFrame.paddingRight  = 15.0;
    graph.plotAreaFrame.paddingBottom = 55.0;
    graph.plotAreaFrame.paddingLeft   = 55.0;
    
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:theme];
    graph.plotAreaFrame.borderLineStyle = nil;
    
    // Add legend
    graph.legend                 = [CPTLegend legendWithGraph:graph];
    //graph.legend.textStyle       = x.titleTextStyle;
    graph.legend.fill            = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
    //graph.legend.borderLineStyle = x.axisLineStyle;
    graph.legend.cornerRadius    = 5.0;
    graph.legend.swatchSize      = CGSizeMake(25.0, 25.0);
    graph.legendAnchor           = CPTRectAnchorBottom;
    graph.legendDisplacement     = CGPointMake(0.0, 12.0);
    
    [graph.plotAreaFrame removeAllAnnotations];
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:@"test"];
    CPTLayerAnnotation *annotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer:graph.plotAreaFrame];
    annotation.rectAnchor = CPTRectAnchorTopLeft;
    annotation.displacement = CGPointMake(0, 0);
    annotation.contentLayer = textLayer;
    annotation.contentAnchorPoint = CGPointMake(0, 1); //top left
    [graph.plotAreaFrame addAnnotation:annotation];
    
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
    if (self.time != nil) {
        if ([self.time count] > 1) {
            
        NSDate *latestTime = [self.time objectAtIndex:[self.time count]-1];
        NSDate *earliestTime;
        float ymin, ymax;
        
        if (self.XaxisChoice.selectedSegment == 0) {
            earliestTime = [self.time objectAtIndex:0];}
        else { earliestTime = [self.time objectAtIndex:self.y.ROI.location]; }
        
        // Axes
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.hostView.hostedGraph.axisSet;
        
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
            ymin = self.y.min * 0.90;
            if (ymin == 0) {
                ymin = -1;
            }
        } else { ymin = [self.YminTextField floatValue]; }
        if (self.YmaxChoice.selectedSegment == 0) {
            ymax = self.y.max * 1.10;
            if (ymax == 0) {
                ymax = 1;
            }
        } else { ymax = [self.YmaxTextField floatValue]; }
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(ymin) length:CPTDecimalFromFloat(ymax-ymin)];
        
        // should calculate the size of major and minor tickintevals needed on the fly
        CPTXYAxis *y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromString([NSString stringWithFormat:@"%f", abs(ymax - ymin)/10.0]);
            NSLog(@"%@", [NSString stringWithFormat:@"%f, %f, %f", ymin, ymax, (ymax - ymin)/10.0]);
        y.minorTicksPerInterval = 1;
        y.title = self.y.name;
        
        //first remove all of the annotations to redraw them
        [graph.plotAreaFrame removeAllAnnotations];
        
        NSString *annotationText = [NSString stringWithFormat:@"avg = %f, sig = %f", self.y.average, self.y.standardDeviation];
        CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:annotationText];
        CPTLayerAnnotation *annotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer:graph.plotAreaFrame];
        annotation.rectAnchor = CPTRectAnchorTopLeft;
        annotation.displacement = CGPointMake(0, 0);
        annotation.contentLayer = textLayer;
        annotation.contentAnchorPoint = CGPointMake(0, 1);//top left
        [self.hostView.hostedGraph.plotAreaFrame addAnnotation:annotation];

        // Update legend
        // self.hostView.hostedGraph.legend.textStyle = x.titleTextStyle;
        // self.hostView.hostedGraph.legend.borderLineStyle = x.axisLineStyle;
        
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
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [[plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];
    
    return num;
}

@end
