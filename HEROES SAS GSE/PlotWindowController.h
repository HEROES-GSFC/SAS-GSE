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
}

@property (nonatomic, strong) IBOutlet CPTGraphHostingView *hostView;
- (IBAction)YminClicked:(NSSegmentedControl *)sender;
- (IBAction)YmaxClicked:(NSSegmentedControl *)sender;
- (IBAction)XaxisClicked:(NSSegmentedControl *)sender;
@property (weak) IBOutlet NSTextField *YminTextField;
@property (weak) IBOutlet NSTextField *YmaxTextField;
@property (weak) IBOutlet NSSegmentedControl *YminChoice;
@property (weak) IBOutlet NSSegmentedControl *YmaxChoice;
@property (weak) IBOutlet NSSegmentedControl *XaxisChoice;
@property (strong) IBOutlet NSWindow *MainWindow;
- (IBAction)TextFieldUpdated:(NSTextField *)sender;

@property (nonatomic, strong) NSDictionary *data;

-(void) update;
- (id)initWithData:(NSDictionary *)inputdata name:(NSString *)name;
@end
