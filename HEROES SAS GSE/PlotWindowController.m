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
@property (nonatomic, strong) NSArray *lineColorList;
@property (nonatomic, strong) NSDate *earliestTime;
@end

@implementation PlotWindowController

@synthesize hostView = _hostView;
@synthesize data = _data;
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
        self.lineColorList = [[NSArray alloc] initWithObjects:[CPTColor redColor], [CPTColor blueColor], [CPTColor greenColor], nil];
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
            NSDictionary *currentData = [self.data objectForKey:key];
            DataSeries *ydata = [currentData objectForKey:@"y"];
            if (i == 0) {
                yAxis.title = ydata.name;
                [self.MainWindow setTitle:ydata.name];
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
    [graph reloadData];
    [self update];
}
#pragma mark -
#pragma mark Plot Data Source Methods

- (IBAction)TextFieldUpdated:(NSTextField *)sender {
    [self update];
}

-(void)update{
    if (self.data != nil) {
        float ymin;
        float ymax;
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
            NSDictionary *currentData = [self.data objectForKey:key];
            DataSeries *ydata = [currentData objectForKey:@"y"];
            NSMutableArray *time = [currentData objectForKey:@"time"];
            if (time.count != 0) {
                if (i == 0) {
                    NSDate *latestTime = [time lastObject];
                    ymin = ydata.min;
                    ymax = ydata.max;
                    if (self.XaxisChoice.selectedSegment == 1) {
                        self.earliestTime = [time objectAtIndex:0]; }
                    else {
                        self.earliestTime = [[time subarrayWithRange:ydata.ROI] objectAtIndex:0]; }
                    timeFormatter.referenceDate = self.earliestTime;
                    xAxis.labelFormatter = timeFormatter;
                    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                                    length:CPTDecimalFromFloat([latestTime timeIntervalSinceDate:self.earliestTime])];
                }
                
                if (ymax < ydata.max){ ymax = ydata.max; }
                if (ymin > ydata.min){ ymin = ydata.min; }
                                
                // add annotation to plot
                NSString *annotationText = [NSString stringWithFormat:@"avg = %f, sig = %f", ydata.average, ydata.standardDeviation];
                CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:annotationText];
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
        [graph reloadData];
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *plot_name = plot.identifier;
    NSDictionary *currentData = [self.data objectForKey:plot_name];
    DataSeries *ydata =[currentData objectForKey:@"y"];
    NSArray *time;
    NSNumber *result;
    
    if (self.XaxisChoice.selectedSegment == 1){
        time = [currentData objectForKey:@"time"];
    } else {
        time = [[currentData objectForKey:@"time"] subarrayWithRange:ydata.ROI];
    }
    if (fieldEnum == CPTScatterPlotFieldX) {
        NSTimeInterval x = [[time objectAtIndex:index] timeIntervalSinceDate:self.earliestTime];
        //NSLog(@"%@", [[time subarrayWithRange:ydata.ROI] objectAtIndex:0]);
        result = [NSNumber numberWithDouble:x];
    }
    if (fieldEnum == CPTScatterPlotFieldY) {
        if (self.XaxisChoice.selectedSegment == 1){
            result = [ydata.data objectAtIndex:index];
        } else {
            result = [[ydata ROIdata] objectAtIndex:index];
        }
    }
    //NSLog(@"numberForPlot: %@", result);
    return result;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSString *plot_name = plot.identifier;
    NSDictionary *currentData = [self.data objectForKey:plot_name];
    DataSeries *ydata = [currentData objectForKey:@"y"];
    if (self.XaxisChoice.selectedSegment == 1){
        return ydata.data.count;
    } else {
        return [ydata ROIdata].count;
    }
}

@end
