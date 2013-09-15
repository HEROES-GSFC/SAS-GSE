//
//  PlotWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 4/14/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "PlotWindowController.h"
#import <CorePlot/CorePlot.h>
#import "TimeSeries.h"

@interface PlotWindowController ()
@property (nonatomic, strong) NSArray *lineColorList;
@property (nonatomic, strong) NSDate *earliestTime;
@end

@implementation PlotWindowController

@synthesize hostView = _hostView;
@synthesize data;
@synthesize YmaxTextField;
@synthesize YminTextField;
@synthesize YminChoice;
@synthesize YmaxChoice;
@synthesize XaxisChoice;
@synthesize lineColorList;
@synthesize MainWindow;
@synthesize earliestTime;

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
    if ([sender selectedSegment] == 0) {
        for (NSString *key in self.data) {
            TimeSeries *currentData = [self.data objectForKey:key];
            currentData.ROIEnabled = YES;
        }
    }
    if ([sender selectedSegment] == 1) {
        for (NSString *key in self.data) {
            TimeSeries *currentData = [self.data objectForKey:key];
            currentData.ROIEnabled = NO;
        }
    }

    [self update];
}

- (id)init{
    return [super initWithWindowNibName:@"PlotWindowController"];
}

- (id)initWithData:(NSDictionary *)inputdata{
    self = [self init];
    self.data = inputdata;
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.lineColorList = [[NSArray alloc] initWithObjects:[CPTColor blackColor], [CPTColor redColor], [CPTColor blueColor], [CPTColor greenColor], [CPTColor orangeColor], [CPTColor purpleColor], [CPTColor grayColor], [CPTColor cyanColor], nil];
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
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.5f;
    majorGridLineStyle.lineColor = [CPTColor grayColor];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    
    // X axes
    CPTXYAxis *xAxis = axisSet.xAxis;
    xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    xAxis.majorIntervalLength = CPTDecimalFromFloat(10);        // one minute
    xAxis.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    xAxis.minorTicksPerInterval       = 5;                      // one every ten s
    xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    xAxis.majorGridLineStyle = majorGridLineStyle;
    
    CPTXYAxis *yAxis = axisSet.yAxis;
    yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    yAxis.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
    yAxis.majorGridLineStyle = majorGridLineStyle;
    
    [graph.plotAreaFrame removeAllAnnotations];
    int i = 0;
    if (self.data != nil) {
        for (NSString *key in self.data) {
            TimeSeries *currentData = [self.data objectForKey:key];
            if (i == 0) {
                yAxis.title = currentData.name;
                [self.MainWindow setTitle:currentData.name];
            }
            
            // Create a plot that uses the data source method
            CPTScatterPlot *linePlot = [[CPTScatterPlot alloc] init];
            linePlot.identifier = key;
            
            // linestyle for data
            CPTMutableLineStyle *lineStyle = [linePlot.dataLineStyle mutableCopy];
            lineStyle.lineWidth = 2.f;
            lineStyle.lineColor = [self.lineColorList objectAtIndex:i];
            linePlot.dataLineStyle = lineStyle;
            linePlot.dataSource = self;
            [graph addPlot:linePlot];
            i++;
        }
    }
    // Add legend
    graph.legend                 = [CPTLegend legendWithGraph:graph];
    graph.legend.textStyle       = xAxis.titleTextStyle;
    graph.legend.fill            = [CPTFill fillWithColor:[CPTColor whiteColor]];
    graph.legend.borderLineStyle = xAxis.axisLineStyle;
    graph.legend.cornerRadius    = 5.0;
    graph.legend.swatchSize      = CGSizeMake(25.0, 25.0);
    graph.legendAnchor           = CPTRectAnchorBottom;
    graph.legendDisplacement     = CGPointMake(0.0, 12.0);
    graph.legend.numberOfRows    = 1;
    
    self.hostView.hostedGraph = graph;
    
    [graph.defaultPlotSpace scaleToFitPlots:[graph allPlots]];
    [graph reloadDataIfNeeded];
    [self update];
}
#pragma mark -
#pragma mark Plot Data Source Methods

- (IBAction)TextFieldUpdated:(NSTextField *)sender {
    [self update];
}

-(void)update{
    if (self.data != nil) {
        float ymin = 0;
        float ymax = 100;
        // Axes
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.hostView.hostedGraph.axisSet;
        CPTXYAxis *yAxis = axisSet.yAxis;
        CPTXYAxis *xAxis = axisSet.xAxis;
        // Setup scatter plot space
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.hostView.hostedGraph.defaultPlotSpace;
        [graph.plotAreaFrame removeAllAnnotations];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
        
        int i = 0;
        for (NSString *key in self.data) {
            TimeSeries *currentData = [self.data objectForKey:key];

            if ([[currentData data]count] != 0) {
                if (i == 0) {
                    ymin = currentData.min * 0.8;
                    ymax = currentData.max * 1.2;
                    
                    self.earliestTime = [currentData earliestTime];
                    
                    timeFormatter.referenceDate = self.earliestTime;
                    xAxis.labelFormatter = timeFormatter;
                    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                                    length:CPTDecimalFromFloat([[currentData latestTime] timeIntervalSinceDate:self.earliestTime])];
                }
                
                if (ymax < currentData.max){ ymax = currentData.max; }
                if (ymin > currentData.min){ ymin = currentData.min; }
                                
                // add annotation to plot
                NSString *annotationText = [NSString stringWithFormat:@"avg = %f, sig = %f", currentData.average, currentData.standardDeviation];
                CPTMutableTextStyle *textStyle = [[CPTMutableTextStyle alloc] init];
                textStyle.color = [self.lineColorList objectAtIndex:i];
                CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:annotationText style: textStyle];
                //textLayer.backgroundColor = [CPTColor redColor];
                CPTLayerAnnotation *annotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer:graph.plotAreaFrame];
                annotation.rectAnchor = CPTRectAnchorTopLeft;
                annotation.displacement = CGPointMake(0 + 200*i, 0);
                annotation.contentLayer = textLayer;
                annotation.contentAnchorPoint = CGPointMake(0, 1);//top left
                [self.hostView.hostedGraph.plotAreaFrame addAnnotation:annotation];
                i++;
            }
        }
        if (self.YmaxChoice.selectedSegment == 1) {
            ymax = [self.YmaxTextField floatValue];
        }
        if (self.YminChoice.selectedSegment == 1) {
            ymin = [self.YminTextField floatValue];}
        
        // should calculate the size of major and minor tickintevals needed on the fly
        yAxis.majorIntervalLength = CPTDecimalFromCGFloat(abs(ymax - ymin)/5.0);
        yAxis.minorTicksPerInterval = 1;
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(ymin)
                                                        length:CPTDecimalFromFloat(abs(ymax - ymin))];
        
        //[graph.defaultPlotSpace scaleToFitPlots:[graph allPlots]];
        [graph reloadDataIfNeeded];
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    TimeSeries *currentData = [self.data objectForKey:plot.identifier];
    
    if (fieldEnum == CPTScatterPlotFieldX) {
        NSTimeInterval x = [[[currentData time] objectAtIndex:index] timeIntervalSinceDate:self.earliestTime];
        return [NSNumber numberWithDouble:x];
    }
    if (fieldEnum == CPTScatterPlotFieldY) {
        return [[currentData data] objectAtIndex:index];
    }
    return [NSNumber numberWithFloat:0];
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    TimeSeries *currentData = [self.data objectForKey:plot.identifier];
    return [[currentData data] count];
}

@end
