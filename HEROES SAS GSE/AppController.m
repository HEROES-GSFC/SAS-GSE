//
//  AppController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/22/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

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

@interface AppController (){
    // transform object goes here
}
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDictionary *listOfCommands;
@property (nonatomic, strong) DataPacket *packet;
@property (nonatomic, strong) NSArray *PlotWindowsAvailable;
- (NSString *)createDateTimeString: (NSString *)type;
- (void)OpenTelemetrySaveTextFiles;
@end

@implementation AppController

// GUI Elements
@synthesize SAS2CPUTemperatureLabel;
@synthesize PYASFCameraTemperatureLabel;
@synthesize SAS1CPUTemperatureLabel;
@synthesize PYASRCameraTemperatureLabel;

@synthesize SAS1FrameNumberLabel;
@synthesize SAS1FrameTimeLabel;
@synthesize SAS2FrameNumberLabel;
@synthesize SAS2FrameTimeLabel;
@synthesize PYASRImageMaxMinTextField;
@synthesize PYASFdrawBkgImage_checkbox;
@synthesize PYASRdrawBkgImage_checkbox;

@synthesize SAS1CmdCountTextField;
@synthesize SAS1CmdKeyTextField;
@synthesize PYASFImageMaxMinTextField;
@synthesize MainWindow;
@synthesize PYASFcameraView = _PYASFcameraView;
@synthesize PYASRcameraView = _PYASRcameraView;
@synthesize Commander_window = _Commander_window;
@synthesize Console_window = _Console_window;
@synthesize Plot_window = _Plot_window;
@synthesize PYASFTemperaturesForm;
@synthesize PYASRTemperaturesForm;
@synthesize TimeProfileMenu;
@synthesize PlotWindows = _PlotWindows;

@synthesize timer = _timer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize packet = _packet;
@synthesize SAS1telemetrySaveFile = _SAS1telemetrySaveFile;
@synthesize SAS2telemetrySaveFile = _SAS2telemetrySaveFile;
@synthesize PYASFtimeSeriesCollection = _PYASFtimeSeriesCollection;
@synthesize PYASRtimeSeriesCollection = _PYASRtimeSeriesCollection;

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
        
        self.PlotWindowsAvailable = [NSArray arrayWithObjects:@"time", @"camera temperature", @"cpu temperature", @"ctl X solution", @"ctl Y solution", @"ctl R solution", nil];
        
        NSMutableArray *PYASFobjects = [[NSMutableArray alloc] init];
        for (NSString *plotName in self.PlotWindowsAvailable) {
            if ([plotName isEqualToString:@"time"]) {
                NSMutableArray *newSeries = [[NSMutableArray alloc] init];
                [PYASFobjects addObject:newSeries];
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
                NSMutableArray *newSeries = [[NSMutableArray alloc] init];
                [PYASRobjects addObject:newSeries];
            } else {
                DataSeries *newSeries = [[DataSeries alloc] init];
                newSeries.name = plotName;
                [PYASRobjects addObject:newSeries];
            }
        }
        self.PYASRtimeSeriesCollection = [NSDictionary dictionaryWithObjects:PYASFobjects forKeys:self.PlotWindowsAvailable];
        
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
    
    NSInteger numberofCols = [self.PYASFTemperaturesForm numberOfColumns];
    NSInteger numberofRows = [self.PYASFTemperaturesForm numberOfRows];
    for (int i=0; i < numberofCols; i++) {
        for (int j=0; j < numberofRows; j++){
            NSFormCell *cell = [self.PYASFTemperaturesForm cellAtRow:j column:i];
            [cell setTitle:[temperatureNames objectAtIndex:i*numberofCols + j]];
            [cell setIntegerValue:0];
            
            cell = [self.PYASRTemperaturesForm cellAtRow:j column:i];
            [cell setTitle:[temperatureNames objectAtIndex:i*numberofCols + j]];
            [cell setIntegerValue:0];
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
    
    [self.queue addOperation:parseOp];	// this will start the "TestOperation"
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
- (NSDictionary *)PYASFtimeSeriesCollection
{
    if (_PYASFtimeSeriesCollection == nil)
    {
        _PYASFtimeSeriesCollection = [[NSDictionary alloc] init];
    }
    return _PYASFtimeSeriesCollection;
}
- (NSDictionary *)PYASRtimeSeriesCollection
{
    if (_PYASRtimeSeriesCollection == nil)
    {
        _PYASRtimeSeriesCollection = [[NSDictionary alloc] init];
    }
    return _PYASRtimeSeriesCollection;
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


- (IBAction)PYASRbkgImageIsClicked:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        self.PYASFcameraView.turnOnBkgImage = TRUE;}
    if ([sender state] == NSOffState){
        self.PYASFcameraView.turnOnBkgImage = FALSE;}
}

- (IBAction)PYASFbkgImageIsClicked:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        self.PYASRcameraView.turnOnBkgImage = TRUE;}
    if ([sender state] == NSOffState){
        self.PYASRcameraView.turnOnBkgImage = FALSE;}
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

- (PlotWindowController *)Plot_window{
    if (_Plot_window == nil) {
        _Plot_window = [[PlotWindowController alloc]init];
    }
    return _Plot_window;
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


- (IBAction)PYASRsaveImage_ButtonAction:(NSButton *)sender {
    
    NSData *imagedata = self.PYASRcameraView.bkgImage;
    
    NSUInteger len = [self.PYASRcameraView.bkgImage length];
    
    long xpixels = self.PYASRcameraView.imageXSize;
    long ypixels = self.PYASRcameraView.imageYSize;
    
    NSBitmapImageRep *greyRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:xpixels pixelsHigh:ypixels bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:xpixels bitsPerPixel:8];
    
    unsigned char *pix = [greyRep bitmapData];
    
    memcpy(pix, [self.PYASRcameraView.bkgImage bytes], len);
    
    NSImage *greyscale = [[NSImage alloc] initWithSize:NSMakeSize(xpixels, ypixels)];
    [greyscale addRepresentation:greyRep];
    
    NSData *temp = [greyscale TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:temp];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imagedata = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    
    //open a save panel
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:[NSString stringWithFormat:@"PYASimage%@.png", [self createDateTimeString:@"file"]]];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *theFile = [panel URL];
            [imagedata writeToFile:[theFile path] atomically:YES];
        }
    }];
}

- (IBAction)PYASFsaveImage_ButtonAction:(NSButton *)sender {
    
    NSData *imagedata = self.PYASFcameraView.bkgImage;
    
    NSUInteger len = [self.PYASFcameraView.bkgImage length];
    
    long xpixels = self.PYASFcameraView.imageXSize;
    long ypixels = self.PYASFcameraView.imageYSize;
    
    NSBitmapImageRep *greyRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:xpixels pixelsHigh:ypixels bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:xpixels bitsPerPixel:8];
    
    unsigned char *pix = [greyRep bitmapData];
    
    memcpy(pix, [self.PYASFcameraView.bkgImage bytes], len);
    
    NSImage *greyscale = [[NSImage alloc] initWithSize:NSMakeSize(xpixels, ypixels)];
    [greyscale addRepresentation:greyRep];
    
    NSData *temp = [greyscale TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:temp];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imagedata = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    
    //open a save panel
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:[NSString stringWithFormat:@"PYASimage%@.png", [self createDateTimeString:@"file"]]];
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
        
        NSString *logMessage = [NSString stringWithFormat:@"Received %@ image. Size is %ldx%ld = %ld", cameraName, self.PYASFcameraView.imageXSize, self.PYASFcameraView.imageYSize, (unsigned long)[data length]];
        [self postToLogWindow:logMessage];
    }
    
    if ([cameraName isEqualToString:@"PYAS-R"]) {
        self.PYASRcameraView.bkgImage = data;
        self.PYASRcameraView.imageXSize = [[notifData valueForKey:@"xsize"] intValue];
        self.PYASRcameraView.imageYSize = [[notifData valueForKey:@"ysize"] intValue];
        self.PYASRcameraView.imageExists = YES;
        self.PYASRcameraView.turnOnBkgImage = YES;
        [self.PYASRcameraView draw];
        
        NSString *logMessage = [NSString stringWithFormat:@"Received %@ image. Size is %ldx%ld = %ld", cameraName, self.PYASFcameraView.imageXSize, self.PYASFcameraView.imageYSize, (unsigned long)[data length]];
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
    
    NSRange CameraOKTempRange = NSMakeRange(-20, 60);
    NSRange CPUOKTempRange = NSMakeRange(-20, 60);
    
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
        
        [self.SAS1FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
        [self.SAS1FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
        [self.SAS1CmdCountTextField setIntegerValue:[self.packet commandCount]];
        [self.SAS1CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];
        
        [[self.PYASFtimeSeriesCollection objectForKey:@"time"] addObject:[NSDate dateWithNaturalLanguageString:[self.packet getframeTimeString]]];
        [[self.PYASFtimeSeriesCollection objectForKey:@"camera temperature"] addPoint:self.packet.cameraTemperature];
        [[self.PYASFtimeSeriesCollection objectForKey:@"cpu temperature"] addPoint:self.packet.cpuTemperature];
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl X solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].x];
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl Y solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].y];
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y,2) + powf([self.packet.CTLCommand pointValue].y,2))];
        
        DataSeries *ctlYValues = [self.PYASFtimeSeriesCollection objectForKey:@"ctl X solution"];
        DataSeries *ctlXValues = [self.PYASFtimeSeriesCollection objectForKey:@"ctl Y solution"];
        
        [[self.PYASFtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y - ctlXValues.average,2) + powf([self.packet.CTLCommand pointValue].y - ctlYValues.average,2))];
        
        [self.PYASFCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
        [self.PYASFCTLSigmaTextField setStringValue:[NSString stringWithFormat:@"%6.2f, %6.2f", ctlXValues.standardDeviation, ctlYValues.standardDeviation]];
        
        if (!NSLocationInRange(self.packet.cameraTemperature, CameraOKTempRange)){
            [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
        } else {[self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]];}
        
        [self.SAS1CPUTemperatureLabel setIntegerValue:self.packet.cpuTemperature];
        if (!NSLocationInRange(self.packet.cpuTemperature, CPUOKTempRange)){
            [self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor redColor]];
        } else {[self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor whiteColor]];}
        
        [self.PYASFCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [self.packet.CTLCommand pointValue].x, [self.packet.CTLCommand pointValue].y]];
        self.PYASFImageMaxMinTextField.stringValue = [NSString stringWithFormat:@"%ld, %ld", (unsigned long)self.packet.ImageRange.location, (unsigned long)self.packet.ImageRange.length];
        
        [self.PYASFcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
        self.PYASFcameraView.chordCrossingPoints = self.packet.chordPoints;
        self.PYASFcameraView.fiducialPoints = self.packet.fiducialPoints;
        [self.PYASFcameraView setScreenCenter:[self.packet.screenCenter pointValue].x :[self.packet.screenCenter pointValue].y];
        self.PYASFcameraView.screenRadius = self.packet.screenRadius;
        
        NSInteger numberofCols = [self.PYASFTemperaturesForm numberOfColumns];
        NSInteger numberofRows = [self.PYASFTemperaturesForm numberOfRows];
        for (int i=0; i < numberofCols; i++) {
            for (int j=0; j < numberofRows; j++){
                NSFormCell *cell = [self.PYASFTemperaturesForm cellAtRow:j column:i];
                [cell setIntegerValue:[[self.packet.i2cTemperatures objectAtIndex:i*numberofCols + j] integerValue]];
            }
        }
        
        self.PYASFcameraView.northAngle = northAngle;
        
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
        //[self.PYASRcameraView draw];
        [self.Plot_window update];
        for (PlotWindowController *PlotWindow in self.PlotWindows) {
            [PlotWindow update];
        }
    }
    
    if (self.packet.isSAS2) {
        
        [self.SAS2FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
        [self.SAS2FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
        [self.SAS2CmdCountTextField setIntegerValue:[self.packet commandCount]];
        [self.SAS2CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];
        
        [self.PYASRCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [self.packet.CTLCommand pointValue].x, [self.packet.CTLCommand pointValue].y]];
        [self.PYASRcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
        self.PYASRcameraView.chordCrossingPoints = self.packet.chordPoints;
        self.PYASRcameraView.fiducialPoints = self.packet.fiducialPoints;
        self.PYASRImageMaxMinTextField.stringValue = [NSString stringWithFormat:@"%ld, %ld", (unsigned long)self.packet.ImageRange.location, (unsigned long)self.packet.ImageRange.length];
        
        [self.PYASRCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
        if (!NSLocationInRange(self.packet.cameraTemperature, CameraOKTempRange)){
            [self.PYASRCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
        } else { [self.PYASRCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]]; }
        
        [self.SAS2CPUTemperatureLabel setIntegerValue:self.packet.cpuTemperature];
        if (!NSLocationInRange(self.packet.cpuTemperature, CPUOKTempRange)){
            [self.SAS2CPUTemperatureLabel setBackgroundColor:[NSColor redColor]];
        } else { [self.SAS2CPUTemperatureLabel setBackgroundColor:[NSColor whiteColor]]; }
        
        [self.PYASRcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
        self.PYASRcameraView.chordCrossingPoints = self.packet.chordPoints;
        self.PYASRcameraView.fiducialPoints = self.packet.fiducialPoints;
        
        DataSeries *ctlYValues = [self.PYASRtimeSeriesCollection objectForKey:@"ctl X solution"];
        DataSeries *ctlXValues = [self.PYASRtimeSeriesCollection objectForKey:@"ctl Y solution"];
        
        [[self.PYASRtimeSeriesCollection objectForKey:@"time"] addObject:[NSDate dateWithNaturalLanguageString:[self.packet getframeTimeString]]];
        [[self.PYASRtimeSeriesCollection objectForKey:@"camera temperature"] addPoint:self.packet.cameraTemperature];
        [[self.PYASRtimeSeriesCollection objectForKey:@"cpu temperature"] addPoint:self.packet.cpuTemperature];
        [[self.PYASRtimeSeriesCollection objectForKey:@"ctl X solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].x];
        [[self.PYASRtimeSeriesCollection objectForKey:@"ctl Y solution"] addPoint:60*60*[self.packet.CTLCommand pointValue].y];
        [[self.PYASRtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y - ctlXValues.average,2) + powf([self.packet.CTLCommand pointValue].y - ctlYValues.average,2))];
        
        NSInteger numberofCols = [self.PYASRTemperaturesForm numberOfColumns];
        NSInteger numberofRows = [self.PYASRTemperaturesForm numberOfRows];
        for (int i=0; i < numberofCols; i++) {
            for (int j=0; j < numberofRows; j++){
                NSFormCell *cell = [self.PYASRTemperaturesForm cellAtRow:j column:i];
                [cell setIntegerValue:[[self.packet.i2cTemperatures objectAtIndex:i*numberofCols + j] integerValue]];
            }
        }
        
        self.PYASRcameraView.northAngle = northAngle;
        
        //[self.PYASFcameraView draw];
        [self.PYASRcameraView draw];
        [self.Plot_window update];
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
            PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:[self.PYASFtimeSeriesCollection objectForKey:@"time"] :[self.PYASFtimeSeriesCollection objectForKey:@"cpu temperature"]];
            [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            [newPlotWindow showWindow:self];
            [sender setState:1];
        } else {
            [self.PlotWindows removeObjectForKey:userChoice];
            [sender setState:0];
        }
    }
    
}

- (IBAction)GraphIsChosen:(NSPopUpButton *)sender {
    if ([sender indexOfSelectedItem] == 0) {
        self.Plot_window.time = [self.PYASFtimeSeriesCollection objectForKey:@"time"];
        self.Plot_window.y = [self.PYASFtimeSeriesCollection objectForKey:@"cpu temperature"];
    }
    if ([sender indexOfSelectedItem] == 1) {
        self.Plot_window.time = [self.PYASFtimeSeriesCollection objectForKey:@"time"];
        self.Plot_window.y = [self.PYASFtimeSeriesCollection objectForKey:@"camera temperature"];
    }
    if ([sender indexOfSelectedItem] == 2) {
        self.Plot_window.time = [self.PYASFtimeSeriesCollection objectForKey:@"time"];
        self.Plot_window.y = [self.PYASFtimeSeriesCollection objectForKey:@"ctl X solution"];
    }
    if ([sender indexOfSelectedItem] == 3) {
        self.Plot_window.time = [self.PYASFtimeSeriesCollection objectForKey:@"time"];
        self.Plot_window.y = [self.PYASFtimeSeriesCollection objectForKey:@"ctl Y solution"];
    }
    if ([sender indexOfSelectedItem] == 4) {
        self.Plot_window.time = [self.PYASFtimeSeriesCollection objectForKey:@"time"];
        self.Plot_window.y = [self.PYASFtimeSeriesCollection objectForKey:@"ctl R solution"];
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
    
    [self.Plot_window update];
    [self postToLogWindow:@"test string"];
    free(pixels);
}

@end
