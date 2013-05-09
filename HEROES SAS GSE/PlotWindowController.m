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
@synthesize lineColorList;
@synthesize MainWindow;

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

- (id)initWithData:(NSMutableArray *)time :(NSDictionary *)data{
    self = [self init];
    self.y = data;
    self.time = time;
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

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
 
    CPTXYAxis *yAxis = axisSet.yAxis;
    yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    yAxis.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
    yAxis.majorGridLineStyle = majorGridLineStyle;
    
    [graph.plotAreaFrame removeAllAnnotations];
    int i = 0;
    for (NSString *key in self.y) {
        DataSeries *ydata = [self.y objectForKey:key];
        if (i == 0) {
            yAxis.title = ydata.name;
            timeFormatter.referenceDate = [self.time objectAtIndex:0];
            xAxis.labelFormatter = timeFormatter;
            [self.MainWindow setTitle:ydata.name];
        }

        // Create a plot that uses the data source method
        CPTScatterPlot *linePlot = [[CPTScatterPlot alloc] init];
        DataSeries *currenty = [self.y objectForKey:key];
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
    
    // Add legend
    graph.legend                 = [CPTLegend legendWithGraph:graph];
    graph.legend.textStyle       = xAxis.titleTextStyle;
    graph.legend.fill            = [CPTFill fillWithColor:[CPTColor whiteColor]];
    graph.legend.borderLineStyle = xAxis.axisLineStyle;
    graph.legend.cornerRadius    = 5.0;
    graph.legend.swatchSize      = CGSizeMake(25.0, 25.0);
    graph.legendAnchor           = CPTRectAnchorBottom;
    graph.legendDisplacement     = CGPointMake(0.0, 12.0);
    
    self.hostView.hostedGraph = graph;
    
    [graph.defaultPlotSpace scaleToFitPlots:[graph allPlots]];
    [graph reloadData];
    [self update];
}
#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 10;
}

- (IBAction)TextFieldUpdated:(NSTextField *)sender {
    [self update];
}

-(void)update{
    if (self.time != nil) {
        if ([self.time count] > 1) {
            float ymin, ymax;

            NSDate *latestTime = [self.time objectAtIndex:[self.time count]-1];
            NSDate *earliestTime;
            
            NSArray *ys = [self.y allValues];
            DataSeries *defaulty = [ys objectAtIndex:0];
            ymin = defaulty.min;
            ymax = defaulty.max;
            
            if (self.XaxisChoice.selectedSegment == 1) {
                earliestTime = [self.time objectAtIndex:0];}
            else { earliestTime = [self.time objectAtIndex:defaulty.ROI.location]; }
            
            // Axes
            CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.hostView.hostedGraph.axisSet;
            
            // Setup scatter plot space
            CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.hostView.hostedGraph.defaultPlotSpace;
            plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                            length:CPTDecimalFromFloat([latestTime timeIntervalSinceDate:earliestTime])];
            [graph.plotAreaFrame removeAllAnnotations];
            int i = 0;
            for (NSString *key in self.y) {
                DataSeries *ydata = [self.y objectForKey:key];
                if (ymin > ydata.min){ ymin = ydata.min; }
                if (ymax < ydata.max){ ymin = ydata.max; }
                
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
            // should calculate the size of major and minor tickintevals needed on the fly
            //CPTXYAxis *y = axisSet.yAxis;
            //y.majorIntervalLength = CPTDecimalFromString([NSString stringWithFormat:@"%f", abs(ymax - ymin)/10.0]);
            //NSLog(@"%@", [NSString stringWithFormat:@"%f, %f, %f", ymin, ymax, (ymax - ymin)/10.0]);
            //y.minorTicksPerInterval = 1;
            [graph.defaultPlotSpace scaleToFitPlots:[graph allPlots]];
            [graph reloadData];
        }
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSArray *ys = [self.y allValues];
    DataSeries *defaulty = [ys objectAtIndex:0];
    NSUInteger indexmin = self.XaxisChoice.selectedSegment == 0 ? 0 : defaulty.ROI.location;
    
    if (fieldEnum == CPTScatterPlotFieldX) {
        NSTimeInterval x = [[self.time objectAtIndex:(index + indexmin)] timeIntervalSinceDate:[self.time objectAtIndex:indexmin]];
        return [NSNumber numberWithFloat:x];
    } else {
        NSString *plot_name = plot.identifier;
        DataSeries *ydata = [self.y objectForKey:plot_name];
        return [ydata.data objectAtIndex:(index + indexmin)];
    }
}

@end
