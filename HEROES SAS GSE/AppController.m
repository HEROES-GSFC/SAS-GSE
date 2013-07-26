//
//  AppController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/22/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//
#define GROUND_NETWORK true
#import "AppController.h"
#import "ParseDataOperation.h"
#import "ParseTCPOperation.h"
#import "DataPacket.h"
#import "lib_crc.h"
#import "CameraView.h"
#import "CommanderWindowController.h"
#import "ConsoleWindowController.h"
#import "DataSeries.h"
#import "Transform.hpp"
#import "RASCameraViewWindow.h"
#import "NumberInRangeFormatter.h"

@interface AppController ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *IndicatorFlipTimer;
@property (nonatomic, strong) NSDictionary *listOfCommands;
@property (nonatomic, strong) DataPacket *packet;
@property (nonatomic, strong) NSArray *PlotWindowsAvailable;
@property (nonatomic, strong) NSArray *IndicatorTimers;
- (NSString *)createDateTimeString: (NSString *)type;
- (void)OpenTelemetrySaveTextFiles;
@end

@implementation AppController

// GUI Elements
@synthesize SAS1CPUTemperatureLabel;
@synthesize SAS2CPUTemperatureLabel;
@synthesize PYASFCameraTemperatureLabel;
@synthesize PYASRCameraTemperatureLabel;

@synthesize SAS1FrameNumberLabel;
@synthesize SAS1FrameTimeLabel;
@synthesize SAS2FrameNumberLabel;
@synthesize SAS2FrameTimeLabel;

@synthesize SAS1CmdCountTextField;
@synthesize SAS1CmdKeyTextField;
@synthesize MainWindow;
@synthesize PYASFcameraView = _PYASFcameraView;
@synthesize PYASRcameraView = _PYASRcameraView;
@synthesize Commander_window = _Commander_window;
@synthesize Console_window = _Console_window;
@synthesize PYASFTemperaturesForm;
@synthesize PYASRTemperaturesForm;
@synthesize TimeProfileMenu;
@synthesize PlotWindows = _PlotWindows;

@synthesize IndicatorFlipTimer = _IndicatorFlipTimer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize packet = _packet;
@synthesize SAS1telemetrySaveFile = _SAS1telemetrySaveFile;
@synthesize SAS2telemetrySaveFile = _SAS2telemetrySaveFile;
@synthesize timeSeriesCollection = _timeSeriesCollection;
@synthesize PYASFtimeSeriesCollection;
@synthesize PYASRtimeSeriesCollection;
@synthesize RAStimeSeriesCollection;
@synthesize rasCameraViewWindow;

@synthesize SAS1AutoFlipSwitch;
@synthesize SAS2AutoFlipSwitch;
@synthesize IndicatorTimers;

- (id)init
{
	self = [super init];
	if (self)
    {
        // read command list dictionary from the CommandList.plist resource file
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CommandList" ofType:@"plist"];
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary *plistDict = (NSDictionary *)[NSPropertyListSerialization
                                                   propertyListFromData:plistXML
                                                   mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                   format:&format
                                                   errorDescription:&errorDesc];
        if (!plistDict) {
            NSLog(@"Error reading plist: %@, format: %ld", errorDesc, format);
        }
        self.listOfCommands = plistDict;
        
        //self.IndicatorFlipTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(FlipIndicators) userInfo:nil repeats:YES];
        
        //NSTimer *SAS1IndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(FlipIndicators) userInfo:nil repeats:YES];
        //NSArray *timerArray = [NSArray arrayWithObjects:<#(id), ...#>, nil]
        
        self.PlotWindowsAvailable = [NSArray arrayWithObjects:@"time", @"camera temperature", @"cpu temperature", @"ctl X solution", @"ctl Y solution", @"ctl R solution", nil];
        
        //NSArray *systemNames = [[NSArray alloc] initWithObjects:@"SAS-1", @"SAS-2", nil];
        //NSArray *cameraNames = [[NSArray alloc] initWithObjects:@"PYAS-F", "PYAS-R", "RAS", nil];
        //NSArray *data = [NSArray arrayWithObjects:@"camera temperature", @"cpu temperature", @"ctl X solution", @"ctl Y solution", nil];
        
        self.PYASFtimeSeriesCollection = [[NSDictionary alloc] init];
        self.PYASRtimeSeriesCollection = [[NSDictionary alloc] init];
        self.RAStimeSeriesCollection = [[NSDictionary alloc] init];
        
        NSMutableArray *PYASFobjects = [[NSMutableArray alloc] init];
        for (NSString *plotName in self.PlotWindowsAvailable) {
            if ([plotName isEqualToString:@"time"]) {
                NSMutableArray *timeArray = [[NSMutableArray alloc] init];
                [PYASFobjects addObject:timeArray];
            } else {
                DataSeries *newSeries = [[DataSeries alloc] init];
                newSeries.name = plotName;
                [PYASFobjects addObject:newSeries];
            }
        }
        self.PYASFtimeSeriesCollection = [NSDictionary dictionaryWithObjects:PYASFobjects forKeys:self.PlotWindowsAvailable];
        
        NSMutableArray *PYASRobjects = [[NSMutableArray alloc] init];
        for (NSString *plotName in self.PlotWindowsAvailable) {
            if ([plotName isEqualToString:@"time"]) {
                NSMutableArray *timeArray = [[NSMutableArray alloc] init];
                [PYASRobjects addObject:timeArray];
            } else {
                DataSeries *newSeries = [[DataSeries alloc] init];
                newSeries.name = plotName;
                [PYASRobjects addObject:newSeries];
            }
        }
        self.PYASRtimeSeriesCollection = [NSDictionary dictionaryWithObjects:PYASRobjects forKeys:self.PlotWindowsAvailable];
        
        DataSeries *RAStemp = [[DataSeries alloc] init];
        RAStemp.name = @"camera temperature";
        self.RAStimeSeriesCollection = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSMutableArray alloc] init], @"time", RAStemp, @"camera temperature", nil];
        
        [self.Commander_window showWindow:nil];
        [self.Commander_window.window orderFront:self];
        
        [self.Console_window showWindow:nil];
        [self.Console_window.window orderFront:self];
        
        [NSApp activateIgnoringOtherApps:YES];
        [self.MainWindow makeKeyAndOrderFront:self];
        [self.MainWindow orderFrontRegardless];
	}
	return self;
}

-(void)awakeFromNib{
    NSArray *temperatureNames = [NSArray arrayWithObjects:@"T1", @"T2", @"T3", @"T4", @"T6", @"T7", nil];
    NumberInRangeFormatter *formatter;
    
    NSInteger numberofCols = [self.PYASFTemperaturesForm numberOfColumns];
    NSInteger numberofRows = [self.PYASFTemperaturesForm numberOfRows];
    for (int i=0; i < numberofCols; i++) {
        for (int j=0; j < numberofRows; j++){
            NumberInRangeFormatter *formatter1 = [[NumberInRangeFormatter alloc] init];
            formatter1.maximum = 100;
            formatter1.minimum = -20;
            
            NSFormCell *cell = [self.PYASFTemperaturesForm cellAtRow:j column:i];
            [cell setTitle:[temperatureNames objectAtIndex:i*numberofRows + j]];
            [cell setIntegerValue:0];
            [cell setEditable:NO];
            [cell setPreferredTextFieldWidth:50.0];
            [cell setFormatter:formatter1];
            
            NumberInRangeFormatter *formatter2 = [[NumberInRangeFormatter alloc] init];
            formatter2.maximum = 100;
            formatter2.minimum = -20;
            cell = [self.PYASRTemperaturesForm cellAtRow:j column:i];
            [cell setTitle:[temperatureNames objectAtIndex:i*numberofRows + j]];
            [cell setIntegerValue:0];
            [cell setEditable:NO];
            [cell setPreferredTextFieldWidth:50.0];
            [cell setFormatter:formatter1];
        }
    }
    
    NSArray *voltages = [NSArray arrayWithObjects:[NSNumber numberWithFloat:10.5], [NSNumber numberWithFloat:2.5], [NSNumber numberWithFloat:3.3], [NSNumber numberWithFloat:5.0], [NSNumber numberWithFloat:12.0], [NSNumber numberWithFloat:12.0], nil ];
    NSArray *voltageNames = [NSArray arrayWithObjects:@"10.5V", @"2.5V", @"3.3V", @"5.0V", @"12.0V", @"", nil];
    numberofCols = [self.PYASFVoltagesForm numberOfColumns];
    numberofRows = [self.PYASFVoltagesForm numberOfRows];
    
    for (NSInteger i = 0; i < numberofCols; i++) {
        for (NSInteger j = 0; j < numberofRows; j++) {
            NumberInRangeFormatter *formatter1 = [[NumberInRangeFormatter alloc] init];
            formatter1.maximum = [[voltages objectAtIndex:(j + i*numberofRows)] floatValue] * 1.2;
            formatter1.minimum = [[voltages objectAtIndex:(j + i*numberofRows)] floatValue] * 0.8;
            
            NSFormCell *cell = [self.PYASFVoltagesForm cellAtRow:j column:i];
            [cell setTitle:[voltageNames objectAtIndex:(j + i*numberofRows)]];
            [cell setIntegerValue:0];
            [cell setEditable:NO];
            [cell setPreferredTextFieldWidth:50.0];
            [cell setFormatter:formatter1];
            
            NumberInRangeFormatter *formatter2 = [[NumberInRangeFormatter alloc] init];
            formatter2.maximum = [[voltages objectAtIndex:(j + i*numberofRows)] floatValue] * 1.2;
            formatter2.minimum = [[voltages objectAtIndex:(j + i*numberofRows)] floatValue] * 0.8;
            
            NSFormCell *cell2 = [self.PYASRVoltagesForm cellAtRow:j column:i];
            [cell2 setTitle:[voltageNames objectAtIndex:(j + i*numberofRows)]];
            [cell2 setIntegerValue:0];
            [cell2 setEditable:NO];
            [cell2 setPreferredTextFieldWidth:50.0];
            [cell2 setFormatter:formatter2];
        }
    }
    
    for (NSString *title in self.PlotWindowsAvailable) {
        if (![title isEqualToString:@"time"]) {
            [self.TimeProfileMenu addItemWithTitle:title action:NULL keyEquivalent:@""];
            NSMenuItem *menuItem = [self.TimeProfileMenu itemWithTitle:title];
            [menuItem setTarget:self];
            [menuItem setAction:@selector(OpenWindow_WindowMenuItemAction:)];
        }
    }
    // start the GetPathsOperation with the root path to start the search
    ParseDataOperation *parseOp = [[ParseDataOperation alloc] init];
    ParseTCPOperation *parseTCP = [[ParseTCPOperation alloc] init];
    
    [self.queue addOperation:parseOp];
    [self.queue addOperation:parseTCP];
    
    if([[self.queue operations] containsObject:parseOp]){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(anyThread_handleData:)
                                                     name:kReceiveAndParseDataDidFinish
                                                   object:nil];
        
    }
    
    if([[self.queue operations] containsObject:parseTCP]){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(anyThread_handleImage:)
                                                     name:kReceiveAndParseImageDidFinish
                                                   object:nil];
    }
    formatter = [self.SAS1CPUTemperatureLabel formatter];
    formatter.maximum = 90;
    formatter.minimum = -20;
    formatter = [self.SAS2CPUTemperatureLabel formatter];
    formatter.maximum = 90;
    formatter.minimum = -20;
    formatter = [self.PYASFCameraTemperatureLabel formatter];
    formatter.maximum = 90;
    formatter.minimum = -20;
    formatter = [self.PYASRCameraTemperatureLabel formatter];
    formatter.maximum = 90;
    formatter.minimum = -20;
    formatter = [self.RASCameraTemperatureLabel formatter];
    formatter.maximum = 90;
    formatter.minimum = -20;
    
    [self OpenTelemetrySaveTextFiles];
    [self postToLogWindow:@"Application started"];
}

- (CommanderWindowController *)Commander_window
{
    if (_Commander_window == nil)
    {
        _Commander_window = [[CommanderWindowController alloc] init];
    }
    return _Commander_window;
}
- (NSMutableDictionary *)PlotWindows
{
    if (_PlotWindows == nil)
    {
        _PlotWindows = [[NSMutableDictionary alloc] init];
    }
    return _PlotWindows;
}

- (ConsoleWindowController *)Console_window
{
    if (_Console_window == nil)
    {
        _Console_window = [[ConsoleWindowController alloc] init];
    }
    return _Console_window;
}

- (NSFileHandle *)SAS1telemetrySaveFile
{
    if (_SAS1telemetrySaveFile == nil)
    {
        _SAS1telemetrySaveFile = [[NSFileHandle alloc] init];
    }
    return _SAS1telemetrySaveFile;
}

- (NSFileHandle *)SAS2telemetrySaveFile
{
    if (_SAS2telemetrySaveFile == nil)
    {
        _SAS2telemetrySaveFile = [[NSFileHandle alloc] init];
    }
    return _SAS2telemetrySaveFile;
}

- (NSOperationQueue *)queue
{
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (NSDictionary *)listOfCommands
{
    if (_listOfCommands == nil) {
        _listOfCommands = [[NSDictionary alloc] init];
    }
    return _listOfCommands;
}

- (CameraView *)PYASRcameraView
{
    if (_PYASRcameraView == nil) {
        _PYASRcameraView = [[CameraView alloc] init];
    }
    return _PYASRcameraView;
}

- (CameraView *)PYASFcameraView
{
    if (_PYASFcameraView == nil) {
        _PYASFcameraView = [[CameraView alloc] init];
    }
    return _PYASFcameraView;
}

- (DataPacket *)packet
{
    if (_packet == nil) {
        _packet = [[DataPacket alloc] init];
    }
    return _packet;
}

//- (IBAction)StartStopButtonAction:(id)sender {
//
//        [self.queue cancelAllOperations];
//
//        // start the GetPathsOperation with the root path to start the search
//        ParseDataOperation *parseOp = [[ParseDataOperation alloc] init];
//        ParseTCPOperation *parseTCP = [[ParseTCPOperation alloc] init];
//
//        [self.queue addOperation:parseOp];	// this will start the "TestOperation"
//        [self.queue addOperation:parseTCP];
//
//        if([[self.queue operations] containsObject:parseOp]){
//            [[NSNotificationCenter defaultCenter] addObserver:self
//                                                     selector:@selector(anyThread_handleData:)
//                                                         name:kReceiveAndParseDataDidFinish
//                                                       object:nil];
//
//            [self.RunningIndicator setHidden:NO];
//            [self.RunningIndicator startAnimation:self];
//        }
//
//        if([[self.queue operations] containsObject:parseTCP]){
//            [[NSNotificationCenter defaultCenter] addObserver:self
//                                                     selector:@selector(anyThread_handleImage:)
//                                                         name:kReceiveAndParseImageDidFinish
//                                                       object:nil];
//        }
//
//        if ([self.SaveData_checkbox state] == NSOnState) {
//            [self OpenTelemetrySaveTextFiles];
//        }
//    }
//    if ([StartStopSegmentedControl selectedSegment] == 1) {
//        // is the following code needed to run on close of application?
//        [self.queue cancelAllOperations];
//        [self.SAS1telemetrySaveFile closeFile];
//        [self.SAS2telemetrySaveFile closeFile];
//    }
//}


- (IBAction)PYASsaveImage_ButtonAction:(NSButton *)sender {
    
    NSData *imagedata;
    NSUInteger len;
    long xpixels, ypixels;
    NSBitmapImageRep *greyRep;
    unsigned char *pix;
    NSString *filenamePrefix;
    
    if ([[sender title] isEqualToString:@"save PYAS-F"]) {
        filenamePrefix = @"PYASF";
        imagedata = self.PYASFcameraView.bkgImage;
        len = [self.PYASFcameraView.bkgImage length];
        
        xpixels = self.PYASFcameraView.imageXSize;
        ypixels = self.PYASFcameraView.imageYSize;
        
        greyRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:xpixels pixelsHigh:ypixels bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:xpixels bitsPerPixel:8];
        
        pix = [greyRep bitmapData];
        
        memcpy(pix, [self.PYASFcameraView.bkgImage bytes], len);
    }
    if ([[sender title] isEqualToString:@"save PYAS-R"]) {
        filenamePrefix = @"PYASR";
        imagedata = self.PYASRcameraView.bkgImage;
        len = [self.PYASRcameraView.bkgImage length];
        
        xpixels = self.PYASRcameraView.imageXSize;
        ypixels = self.PYASRcameraView.imageYSize;
        
        greyRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:xpixels pixelsHigh:ypixels bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:xpixels bitsPerPixel:8];
        
        pix = [greyRep bitmapData];
        
        memcpy(pix, [self.PYASRcameraView.bkgImage bytes], len);
    }
    
    NSImage *greyscale = [[NSImage alloc] initWithSize:NSMakeSize(xpixels, ypixels)];
    [greyscale addRepresentation:greyRep];
    
    NSData *temp = [greyscale TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:temp];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imagedata = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    
    //open a save panel
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:[NSString stringWithFormat:@"%@image%@.png", filenamePrefix, [self createDateTimeString:@"file"]]];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *theFile = [panel URL];
            [imagedata writeToFile:[theFile path] atomically:YES];
        }
    }];
}

- (NSString *)createDateTimeString: (NSString *)type{
    // Create a time string with the format YYYYMMdd_HHmmss
    // This can be used in file names (for example)
    //
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    if ([type isEqualToString:@"file"]) {
        [dateFormatter setDateFormat:@"YYYYMMdd_HHmmss"];
    } else {
        [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    }
    
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    return dateString;
}

- (void)anyThread_handleData:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(mainThread_handleData:) withObject:note waitUntilDone:NO];
}

- (void)anyThread_handleImage:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(mainThread_handleImage:) withObject:note waitUntilDone:NO];
}

- (void)mainThread_handleImage:(NSNotification *)note
{
    NSDictionary *notifData = [note userInfo];
    NSData *data = [notifData valueForKey:@"image"];
    NSString *cameraName = [notifData valueForKey:@"camera"];
    
    if ([cameraName isEqualToString:@"PYAS-F"]) {
        self.PYASFcameraView.bkgImage = data;
        self.PYASFcameraView.imageXSize = [[notifData valueForKey:@"xsize"] intValue];
        self.PYASFcameraView.imageYSize = [[notifData valueForKey:@"ysize"] intValue];
        self.PYASFcameraView.imageExists = YES;
        self.PYASFcameraView.turnOnBkgImage = YES;
        [self.PYASFcameraView draw];
        
        NSString *logMessage = [NSString stringWithFormat:@"Received %@ image. Size is %dx%d = %ld", cameraName, self.PYASFcameraView.imageXSize, self.PYASFcameraView.imageYSize, (unsigned long)[data length]];
        [self postToLogWindow:logMessage];
    }
    
    if ([cameraName isEqualToString:@"PYAS-R"]) {
        self.PYASRcameraView.bkgImage = data;
        self.PYASRcameraView.imageXSize = [[notifData valueForKey:@"xsize"] intValue];
        self.PYASRcameraView.imageYSize = [[notifData valueForKey:@"ysize"] intValue];
        self.PYASRcameraView.imageExists = YES;
        self.PYASRcameraView.turnOnBkgImage = YES;
        [self.PYASRcameraView draw];
        
        NSString *logMessage = [NSString stringWithFormat:@"Received %@ image. Size is %dx%d = %ld", cameraName, self.PYASFcameraView.imageXSize, self.PYASFcameraView.imageYSize, (unsigned long)[data length]];
        [self postToLogWindow:logMessage];
    }
    if ([cameraName isEqualToString:@"RAS"]) {
        self.rasCameraViewWindow = [[RASCameraViewWindow alloc] init];
        [self.rasCameraViewWindow showWindow:self];
        self.rasCameraViewWindow.cameraView.bkgImage = data;
        self.rasCameraViewWindow.cameraView.imageXSize = [[notifData valueForKey:@"xsize"] intValue];
        self.rasCameraViewWindow.cameraView.imageYSize = [[notifData valueForKey:@"ysize"] intValue];
        self.rasCameraViewWindow.cameraView.imageExists = YES;
        self.rasCameraViewWindow.cameraView.turnOnBkgImage = YES;
        [self.rasCameraViewWindow.cameraView draw];
        NSString *logMessage = [NSString stringWithFormat:@"Received %@ image. Size is %dx%d = %ld", cameraName, self.rasCameraViewWindow.cameraView.imageXSize, self.rasCameraViewWindow.cameraView.imageYSize, (unsigned long)[data length]];
        [self postToLogWindow:logMessage];
    }
}

- (void)postToLogWindow: (NSString *)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:@"message"]];
}

- (void)OpenTelemetrySaveTextFiles{
    // Open a file to save the telemetry stream to
    // The file is a csv file
    //
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"HEROES_SAS1_tmlog_%@.txt", [self createDateTimeString:@"file"]];
    
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    // open file to save data stream
    self.SAS1telemetrySaveFile = [NSFileHandle fileHandleForWritingAtPath: filePath ];
    if (self.SAS1telemetrySaveFile == nil) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        self.SAS1telemetrySaveFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    //say to handle where's the file fo write
    [self.SAS1telemetrySaveFile truncateFileAtOffset:[self.SAS1telemetrySaveFile seekToEndOfFile]];
    NSString *writeString = [NSString stringWithFormat:@"HEROES SAS1 Telemetry Log File %@\n", [self createDateTimeString:nil]];
    //position handle cursor to the end of file
    [self.SAS1telemetrySaveFile writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    writeString = [NSString stringWithFormat:@"doy time, frame number, camera temp, cpu temp, suncenter x, suncenter y, CTL x, CTL y\n"];
    [self.SAS1telemetrySaveFile writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)mainThread_handleData:(NSNotification *)note
{
    // Pending NSNotifications can possibly back up while waiting to be executed,
    // and if the user stops the queue, we may have left-over pending
    // notifications to process.
    //
    // So make sure we have "active" running NSOperations in the queue
    // if we are to continuously add found image files to the table view.
    // Otherwise, we let any remaining notifications drain out.
    //
    NSDictionary *notifData = [note userInfo];
    self.packet = [notifData valueForKey:@"packet"];
    
    Transform NorthTransform;
    double northAngle;
    
    //calculate the solar north angle here and pass it to PYASFcameraView
    NorthTransform.getSunAzEl();
    northAngle = NorthTransform.getOrientation();
    //this code assumes that up on the screen is the zenith (which it is not)
    if (northAngle <= 180){  //should add a check for <0 degrees or >360 degrees
        northAngle = 180 - northAngle;
    }
    else {
        northAngle = 540 - northAngle;
    }
    
    if (self.packet.isSAS1) {
        [self.SAS1AutoFlipSwitch reset];
        [self.SAS1FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
        [self.SAS1FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
        
        [self.SAS1CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];
        
        [[self.PYASFtimeSeriesCollection objectForKey:@"time"] addObject:[self.packet getDate]];
        [[self.PYASFtimeSeriesCollection objectForKey:@"camera temperature"] addPoint:self.packet.cameraTemperature];
        [[self.PYASFtimeSeriesCollection objectForKey:@"cpu temperature"] addPoint:self.packet.cpuTemperature];
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl X solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].x];
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl Y solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].y];
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y,2) + powf([self.packet.CTLCommand pointValue].y,2))];
        
        DataSeries *ctlYValues = [self.PYASFtimeSeriesCollection objectForKey:@"ctl X solution"];
        DataSeries *ctlXValues = [self.PYASFtimeSeriesCollection objectForKey:@"ctl Y solution"];
        
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y - ctlXValues.average,2) + powf([self.packet.CTLCommand pointValue].y - ctlYValues.average,2))];
        
        [self.PYASFCTLSigmaTextField setStringValue:[NSString stringWithFormat:@"%6.2f, %6.2f", ctlXValues.standardDeviation, ctlYValues.standardDeviation]];
        
        [self.PYASFCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [self.packet.CTLCommand pointValue].x, [self.packet.CTLCommand pointValue].y]];
        self.PYASFImageMaxTextField.intValue = self.packet.ImageMax;
        
        [self.PYASFcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
        self.PYASFcameraView.chordCrossingPoints = self.packet.chordPoints;
        self.PYASFcameraView.fiducialPoints = self.packet.fiducialPoints;
        [self.PYASFcameraView setScreenCenter:[self.packet.screenCenter pointValue].x :[self.packet.screenCenter pointValue].y];
        self.PYASFcameraView.screenRadius = self.packet.screenRadius;
        
        [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        [self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        
        switch (self.packet.frameNumber % 8) {
            case 0:
                [self.SAS1CPUTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cpuTemperature]];
                [self.PYASFCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
                if (self.packet.cameraTemperature != 0) {
                    [self.PYASFAutoFlipSwitch reset];
                }
                break;
            case 1:
                [self.PYASFCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
                if (self.packet.cameraTemperature != 0) {
                    [self.PYASFAutoFlipSwitch reset];
                }
                [[self.PYASFTemperaturesForm cellAtRow:0 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:0] floatValue]];
                break;
            case 2:
                [[self.PYASFTemperaturesForm cellAtRow:1 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [[self.PYASFVoltagesForm cellAtRow:0 column:0] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:0] floatValue]];
                break;
            case 3:
                [[self.PYASFTemperaturesForm cellAtRow:2 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [[self.PYASFVoltagesForm cellAtRow:1 column:0] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:1] floatValue]];
                break;
            case 4:
                [[self.PYASFTemperaturesForm cellAtRow:3 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [[self.PYASFVoltagesForm cellAtRow:2 column:0] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:2] floatValue]];
                break;
            case 5:
                [[self.PYASFTemperaturesForm cellAtRow:0 column:1] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [[self.PYASFVoltagesForm cellAtRow:0 column:1] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:3] floatValue]];
                break;
            case 6:
                [[self.PYASFTemperaturesForm cellAtRow:1 column:1] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [[self.PYASFVoltagesForm cellAtRow:1 column:1] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:4] floatValue]];
                break;
            case 7:
                [[self.PYASFTemperaturesForm cellAtRow:2 column:1] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:6] floatValue]];
                // add is image saving here
                break;
            default:
                break;
        }
        //        if (self.PYASFCameraTemperatureLabel.floatValue > CameraOKTempRange[1])
        //            [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
        //        if (self.PYASFCameraTemperatureLabel.floatValue < CameraOKTempRange[0])
        //            [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor blueColor]];
        //
        //        if (self.packet.cpuTemperature > CPUOKTempRange[1])
        //            [self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor redColor]];
        //        if (self.packet.cpuTemperature < CPUOKTempRange[0])
        //            [self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor blueColor]];
        //
        
        [self.PYASFAspectErrorCodeTextField setIntegerValue:self.packet.aspectErrorCode];
        [self.PYASFisTracking_indicator setIntValue:1*self.packet.isTracking];
        [self.PYASFProvidingCTL_indicator setIntValue:1*self.packet.isOutputting];
        [self.SAS1ClockSync_indicator setIntValue:1*self.packet.isClockSynced];
        [self.PYASFFoundSun_indicator setIntValue:1*self.packet.isSunFound];
        
        self.PYASFcameraView.northAngle = northAngle;
        
        NSInteger index = 0;
        for (NSNumber *voltage in self.packet.sbcVoltages) {
            [[self.PYASFVoltagesForm cellAtIndex:index] setIntegerValue:[voltage integerValue]];
            index++;
        }
        
        NSString *writeString = [NSString stringWithFormat:@"%@, %@, %@, %@, %@, %@\n",
                                 self.SAS1FrameTimeLabel.stringValue,
                                 self.SAS1FrameNumberLabel.stringValue,
                                 self.PYASFCameraTemperatureLabel.stringValue,
                                 self.SAS1CPUTemperatureLabel.stringValue,
                                 [NSString stringWithFormat:@"%f, %f", [self.packet.sunCenter pointValue].x,
                                  [self.packet.sunCenter pointValue].y],
                                 [NSString stringWithFormat:@"%f, %f", [self.packet.CTLCommand pointValue].x,
                                  [self.packet.CTLCommand pointValue].y]
                                 ];
        [self.SAS1telemetrySaveFile writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
        
        [self.PYASFcameraView draw];
    }
    
    if (self.packet.isSAS2) {
        //[self.SAS2AutoFlipSwitch reset];
        [self.SAS2FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
        [self.SAS2FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
        [self.SAS2CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];
        
        [self.PYASRCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [self.packet.CTLCommand pointValue].x, [self.packet.CTLCommand pointValue].y]];
        
        [self.PYASRcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
        self.PYASRcameraView.chordCrossingPoints = self.packet.chordPoints;
        self.PYASRcameraView.fiducialPoints = self.packet.fiducialPoints;
        [self.PYASRcameraView setScreenCenter:[self.packet.screenCenter pointValue].x :[self.packet.screenCenter pointValue].y];
        self.PYASRcameraView.screenRadius = self.packet.screenRadius;
        
        if (self.packet.frameNumber % 2) {
            self.PYASRImageMaxTextField.intValue = self.packet.ImageMax;
        } else {
            self.RASImageMaxTextField.intValue = self.packet.ImageMax;
        }
        //NSLog(@"SAS-2 %@", [self.packet getframeTimeString]);
        
        //        if ([self.packet frameNumber] % 2){
        //            [self.PYASRCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
        //            [[self.PYASRtimeSeriesCollection objectForKey:@"camera temperature"] addPoint:self.packet.cameraTemperature];
        //            [self.PYASRCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        //            if (self.packet.cameraTemperature > CameraOKTempRange[1])
        //                [self.PYASRCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
        //            if (self.packet.cameraTemperature < CameraOKTempRange[0])
        //                [self.PYASRCameraTemperatureLabel setBackgroundColor:[NSColor blueColor]];
        //            if (self.packet.cameraTemperature != 0) {
        //                [self.PYASF_indicator setIntValue:GREEN_INDICATOR];
        //            } else {
        //                [self.PYASF_indicator setIntValue:RED_INDICATOR];
        //            }
        //
        //        } else {
        //            [self.RASCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
        //            [[self.RAStimeSeriesCollection objectForKey:@"time"] addObject:[self.packet getDate]];
        //            [[self.RAStimeSeriesCollection objectForKey:@"camera temperature"] addPoint:self.packet.cameraTemperature];
        //            [self.RASCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        //            if (self.packet.cameraTemperature > CameraOKTempRange[1])
        //                [self.RASCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
        //            if (self.packet.cameraTemperature < CameraOKTempRange[0])
        //                [self.RASCameraTemperatureLabel setBackgroundColor:[NSColor blueColor]];
        //            if (self.packet.cameraTemperature != 0) {
        //                [self.RAS_indicator setIntValue:GREEN_INDICATOR];
        //            } else {
        //                [self.RAS_indicator setIntValue:RED_INDICATOR];
        //            }
        //
        //        }
        //        [self.SAS2CPUTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cpuTemperature]];
        //        [self.SAS2CPUTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        //        if (self.packet.cpuTemperature > CPUOKTempRange[1])
        //            [self.SAS2CPUTemperatureLabel setBackgroundColor:[NSColor redColor]];
        //        if (self.packet.cpuTemperature < CPUOKTempRange[0])
        //            [self.SAS2CPUTemperatureLabel setBackgroundColor:[NSColor blueColor]];
        //
        [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        [self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        
        switch (self.packet.frameNumber % 8) {
            case 0:
                [self.SAS2CPUTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cpuTemperature]];
                [self.PYASRCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
                if (self.packet.cameraTemperature != 0) {
                    [self.PYASRAutoFlipSwitch reset];
                }
                break;
            case 1:
                [self.RASCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
                if (self.packet.cameraTemperature != 0) {
                    [self.RASAutoFlipSwitch reset];
                }
                [[self.PYASRTemperaturesForm cellAtRow:0 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:0] floatValue]];
                break;
            case 2:
                [[self.PYASRTemperaturesForm cellAtRow:1 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [[self.PYASRVoltagesForm cellAtRow:0 column:0] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:0] floatValue]];
                break;
            case 3:
                [[self.PYASRTemperaturesForm cellAtRow:2 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [[self.PYASRVoltagesForm cellAtRow:1 column:0] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:1] floatValue]];
                break;
            case 4:
                [[self.PYASRTemperaturesForm cellAtRow:3 column:0] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [[self.PYASRVoltagesForm cellAtRow:2 column:0] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:2] floatValue]];
                break;
            case 5:
                [[self.PYASRTemperaturesForm cellAtRow:0 column:1] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [[self.PYASRVoltagesForm cellAtRow:0 column:1] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:3] floatValue]];
                break;
            case 6:
                [[self.PYASRTemperaturesForm cellAtRow:1 column:1] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [[self.PYASRVoltagesForm cellAtRow:1 column:1] setFloatValue:[[self.packet.sbcVoltages objectAtIndex:4] floatValue]];
                break;
            case 7:
                [[self.PYASRTemperaturesForm cellAtRow:2 column:1] setFloatValue:[[self.packet.i2cTemperatures objectAtIndex:6] floatValue]];
                // add is image saving here
                break;
            default:
                break;
        }
        
        DataSeries *ctlYValues = [self.PYASRtimeSeriesCollection objectForKey:@"ctl X solution"];
        DataSeries *ctlXValues = [self.PYASRtimeSeriesCollection objectForKey:@"ctl Y solution"];
        
        [[self.PYASRtimeSeriesCollection objectForKey:@"time"] addObject:[self.packet getDate]];
        [[self.PYASRtimeSeriesCollection objectForKey:@"cpu temperature"] addPoint:self.packet.cpuTemperature];
        [[self.PYASRtimeSeriesCollection objectForKey:@"ctl X solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].x];
        [[self.PYASRtimeSeriesCollection objectForKey:@"ctl Y solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].y];
        [[self.PYASRtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y - ctlXValues.average,2) + powf([self.packet.CTLCommand pointValue].y - ctlYValues.average,2))];
        
        self.PYASRcameraView.northAngle = northAngle;
        
        [self.PYASRAspectErrorCodeTextField setIntegerValue:self.packet.aspectErrorCode];
        [self.PYASRisTracking_indicator setIntValue:1*self.packet.isTracking];
        [self.PYASRProvidingCTL_indicator setIntValue:1*self.packet.isOutputting];
        [self.SAS2ClockSync_indicator setIntValue:1*self.packet.isClockSynced];
        [self.PYASRFoundSun_indicator setIntValue:1*self.packet.isSunFound];
        
        //[self.PYASFcameraView draw];
        [self.PYASRcameraView draw];
    }
    // Update the plot windows
    for (id key in self.PlotWindows) {
        [[self.PlotWindows objectForKey:key] update];
    }
}

- (IBAction)OpenWindow_WindowMenuItemAction:(NSMenuItem *)sender {
    NSString *userChoice = [sender title];
    
    if ([userChoice isEqual: @"Commander"]) {
        [self.Commander_window showWindow:nil];
    }
    if ([userChoice isEqual: @"Console"]) {
        [self.Console_window showWindow:nil];
    }
    if ([self.PlotWindowsAvailable containsObject:userChoice]) {
        if ([self.PlotWindows objectForKey:userChoice] == nil) {
            if ([userChoice isEqualToString:@"camera temperature"]) {
                NSDictionary *PYASFData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.PYASFtimeSeriesCollection objectForKey:@"time"], @"time", [self.PYASFtimeSeriesCollection objectForKey:userChoice], @"y", nil];
                NSDictionary *PYASRData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.PYASRtimeSeriesCollection objectForKey:@"time"], @"time", [self.PYASRtimeSeriesCollection objectForKey:userChoice], @"y", nil];
                NSDictionary *RASData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.RAStimeSeriesCollection objectForKey:@"time"], @"time", [self.RAStimeSeriesCollection objectForKey:userChoice], @"y", nil];
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      PYASFData , @"PYAS-F",
                                      PYASRData , @"PYAS-R",
                                      RASData, @"RAS", nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            } else {
                NSDictionary *PYASFData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.PYASFtimeSeriesCollection objectForKey:@"time"], @"time", [self.PYASFtimeSeriesCollection objectForKey:userChoice], @"y", nil];
                NSDictionary *PYASRData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.PYASRtimeSeriesCollection objectForKey:@"time"], @"time", [self.PYASRtimeSeriesCollection objectForKey:userChoice], @"y", nil];
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      PYASFData , @"PYAS-F",
                                      PYASRData , @"PYAS-R", nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            [sender setState:1];
        } else {
            [self.PlotWindows removeObjectForKey:userChoice];
            [sender setState:0];
        }
    }
    
}

- (IBAction)ClearPYASBkgImage:(NSButton *)sender {
    if ([[sender title] isEqualToString:@"Clear PYAS-F Image"]) {
        self.PYASFcameraView.bkgImage = nil;
    }
    if ([[sender title] isEqualToString:@"Clear PYAS-R Image"]) {
        self.PYASRcameraView.bkgImage = nil;
    }
}

- (IBAction)RunTest:(id)sender {
    int xpixels = 1296;
    int ypixels = 966;
    NSUInteger len = xpixels * ypixels;
    Byte *pixels = (Byte *)malloc(len);
    for (int ix = 0; ix < xpixels; ix++) {
        for (int iy = 0; iy < ypixels; iy++) {
            pixels[ix + iy*xpixels] = pow(pow(ix - xpixels/2.0,2) + pow(iy - ypixels/2.0,2),0.5)/1616.0 * 255;
        }
    }
    
    NSData *data = [NSData dataWithBytes:pixels length:sizeof(uint8_t) * xpixels * ypixels];
    
    self.PYASFcameraView.bkgImage = data;
    self.PYASFcameraView.imageXSize = xpixels;
    self.PYASFcameraView.imageYSize = ypixels;
    self.PYASFcameraView.imageExists = YES;
    self.PYASFcameraView.turnOnBkgImage = YES;
    [self.PYASFcameraView draw];
    
    [self postToLogWindow:@"test string"];
    free(pixels);
    [self.PYASFCameraTemperatureLabel setIntegerValue:-30];
    [self.PYASRCameraTemperatureLabel setIntegerValue:-30];
    [self.SAS1CPUTemperatureLabel setIntegerValue:100];
    
    DataSeries *PYASFcamTemp = [self.PYASFtimeSeriesCollection objectForKey:@"camera temperature"];
    DataSeries *PYASRcamTemp = [self.PYASRtimeSeriesCollection objectForKey:@"camera temperature"];
    DataSeries *RAScamTemp = [self.RAStimeSeriesCollection objectForKey:@"camera temperature"];
    for (int i = 0; i < 10; i++) {
        //NSDate *currentDate = [NSDate date];
        [[self.PYASFtimeSeriesCollection objectForKey:@"time"] addObject:[NSDate dateWithTimeInterval:i sinceDate:[NSDate date]]];
        [PYASFcamTemp addPoint:(float)rand()/RAND_MAX * 5];
        [PYASRcamTemp addPoint:(float)rand()/RAND_MAX * 5];
        [RAScamTemp addPoint:(float)rand()/RAND_MAX * 5];
    }
    // Update the plot windows
    for (id key in self.PlotWindows) {
        [[self.PlotWindows objectForKey:key] update];
    }
}

@end
