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
#import "ConsoleWindowController.h"
#import "DataSeries.h"
#import "TimeSeries.h"
#import "Transform.hpp"
#import "RASCameraViewWindow.h"
#import "NumberInRangeFormatter.h"
#import "UDPSender.hpp"
#import "TCPSender.hpp"
#import "Packet.hpp"

#define GROUND_NETWORK true /* Change this as appropriate */

#define GROUND_NETWORK_PORT 2003 /* The telemetry port on the ground network */
#define FLIGHT_NETWORK_PORT 2002 /* The telemetry port on the flight network */
#define TPCPORT_FOR_IMAGE_DATA 2013
#define IP_LOOPBACK "127.0.0.1"

@interface AppController ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *IndicatorFlipTimer;
@property (nonatomic, strong) NSDictionary *listOfCommands;
@property (nonatomic, strong) NSArray *PlotWindowsAvailable;
@property (nonatomic, strong) NSArray *IndicatorTimers;
- (NSString *)createDateTimeString: (NSString *)type;
- (void)OpenTelemetrySaveTextFiles;
- (void)StartListeningForUDP: (int)port;
- (void)StartListeningForTCP;
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
@synthesize Console_window = _Console_window;

@synthesize TimeProfileMenu;
@synthesize PlotWindows = _PlotWindows;

@synthesize IndicatorFlipTimer = _IndicatorFlipTimer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize SAS1telemetrySaveFile = _SAS1telemetrySaveFile;
@synthesize SAS2telemetrySaveFile = _SAS2telemetrySaveFile;
@synthesize timeSeriesCollection = _timeSeriesCollection;
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
        
        self.PlotWindowsAvailable = [NSArray arrayWithObjects:@"camera temperature", @"cpu temperature", @"ctl X solution", @"ctl Y solution", @"ctl R solution", nil];
        
        //NSArray *systemNames = [[NSArray alloc] initWithObjects:@"SAS-1", @"SAS-2", nil];
        //NSArray *cameraNames = [[NSArray alloc] initWithObjects:@"PYAS-F", "PYAS-R", "RAS", nil];
        //NSArray *data = [NSArray arrayWithObjects:@"camera temperature", @"cpu temperature", @"ctl X solution", @"ctl Y solution", nil];

        self.timeSeriesCollection = [[NSDictionary alloc] init];

        NSArray *timeSeriesNames = [NSArray arrayWithObjects:@"SAS1 cpu temperature", @"SAS2 cpu temperature", @"PYAS-F camera temperature", @"PYAS-R camera temperature", @"RAS camera temperature", @"SAS1 ctl X solution", @"SAS1 ctl Y solution", @"SAS1 ctl R solution", @"SAS2 ctl X solution", @"SAS2 ctl Y solution", @"SAS2 ctl R solution", nil];
        
        NSMutableArray *allTimeSeries = [[NSMutableArray alloc] init];
        
        for (NSString *seriesName in timeSeriesNames) {
            TimeSeries *timeSeries = [[TimeSeries alloc] init];
            timeSeries.name = seriesName;
            [allTimeSeries addObject:timeSeries];
        }
        
        self.PYASFcameraView = [[CameraView alloc] init];
        self.PYASRcameraView = [[CameraView alloc] init];

        self.timeSeriesCollection = [NSDictionary dictionaryWithObjects:allTimeSeries forKeys:timeSeriesNames];
        
        [self.Console_window showWindow:nil];
        [self.Console_window.window orderFront:self];
        
        [NSApp activateIgnoringOtherApps:YES];
        [self.MainWindow makeKeyAndOrderFront:self];
        [self.MainWindow orderFrontRegardless];
	}
	return self;
}

-(void)awakeFromNib{
    
    NumberInRangeFormatter *formatter;
    
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

    NumberInRangeFormatter *TemperatureFormatter = [[NumberInRangeFormatter alloc] init];
    TemperatureFormatter.maximum = 100;
    TemperatureFormatter.minimum = -20;
    
    formatter = [self.SAS1T0TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1T1TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1T2TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1T3TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1T4TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1T5TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    
    formatter = [self.SAS2T0TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2T1TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2T2TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2T3TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2T4TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2T5TextField formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    
    formatter = [self.SAS1V0TextField formatter];
    formatter.maximum = 1.05 * 1.2;
    formatter.minimum = 0.80;
    [self.SAS1V0TextField setFormatter:formatter];
    formatter = [self.SAS2V0TextField formatter];
    formatter.maximum = 1.05 * 1.20;
    formatter.minimum = 0.80;
    
    formatter = [self.SAS1V1TextField formatter];
    formatter.maximum = 2.5 * 1.20;
    formatter.minimum = 2.5 * 0.80;
    formatter = [self.SAS2V1TextField formatter];
    formatter.maximum = 2.5 * 1.20;
    formatter.minimum = 2.5 * 0.80;
    
    formatter = [self.SAS1V2TextField formatter];
    formatter.maximum = 3.3 * 1.20;
    formatter.minimum = 3.3 * 0.80;
    formatter = [self.SAS2V2TextField formatter];
    formatter.maximum = 3.3 * 1.20;
    formatter.minimum = 3.3 * 0.80;
    
    formatter = [self.SAS1V3TextField formatter];
    formatter.maximum = 5.0 * 1.20;
    formatter.minimum = 5.0 * 0.80;
    formatter = [self.SAS2V3TextField formatter];
    formatter.maximum = 5.0 * 1.20;
    formatter.minimum = 5.0 * 0.80;
    
    formatter = [self.SAS1V4TextField formatter];
    formatter.maximum = 12.0 * 1.20;
    formatter.minimum = 12.0 * 0.80;
    formatter = [self.SAS2V4TextField formatter];
    formatter.maximum = 12.0 * 1.20;
    formatter.minimum = 12.0 * 0.80;
    
    for (NSString *title in self.PlotWindowsAvailable) {
            [self.TimeProfileMenu addItemWithTitle:title action:NULL keyEquivalent:@""];
            NSMenuItem *menuItem = [self.TimeProfileMenu itemWithTitle:title];
            [menuItem setTarget:self];
            [menuItem setAction:@selector(OpenWindow_WindowMenuItemAction:)];

    }
    
    [self StartListeningForUDP: GROUND_NETWORK_PORT];
    [self StartListeningForTCP];
            
    [self OpenTelemetrySaveTextFiles];
    [self postToLogWindow:@"Application started"];
}

- (void)StartListeningForUDP: (int)port {
    ParseDataOperation *parseOp = [[ParseDataOperation alloc] initWithPort:port];
    [self.queue addOperation:parseOp];
    if([[self.queue operations] containsObject:parseOp]){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(anyThread_handleData:)
                                                     name:kReceiveAndParseDataDidFinish
                                                   object:nil];
        
    }
}

- (void)SetNewNetworkLocation:(NSPopUpButton *)sender{
    
    NSLog(@"You chose %@", [sender titleOfSelectedItem]);
    [self postToLogWindow:@"Stopping UDP and TCP listeners"];
    [self.queue cancelAllOperations];
    
    //[self.queue waitUntilAllOperationsAreFinished];
    [self postToLogWindow:@"UDP and TCP listeners are stopped"];
    if ([[sender titleOfSelectedItem] isEqualToString:@"Ground"]) {
        UDPSender udpSender = UDPSender(IP_LOOPBACK, FLIGHT_NETWORK_PORT);
        udpSender.init_connection();
        uint8_t temp[1];
        Packet packet = Packet(temp,(uint16_t)1);
        udpSender.send(&packet);
        udpSender.close_connection();
        
        ImagePacket imagePacket = ImagePacket(1, 1);
        TCPSender tcpSender = TCPSender(IP_LOOPBACK, TPCPORT_FOR_IMAGE_DATA);
        tcpSender.init_connection();
        tcpSender.send_packet(&imagePacket);
        tcpSender.close_connection();
        [self.queue waitUntilAllOperationsAreFinished];
        [self StartListeningForUDP: GROUND_NETWORK_PORT];
        [self StartListeningForTCP];
    }
    if ([[sender titleOfSelectedItem] isEqualToString:@"Flight"]) {
        UDPSender udpSender = UDPSender(IP_LOOPBACK, GROUND_NETWORK_PORT);
        udpSender.init_connection();
        uint8_t temp[1];
        Packet packet = Packet(temp,(uint16_t)1);
        udpSender.send(&packet);
        udpSender.close_connection();
        
        ImagePacket imagePacket = ImagePacket(1, 1);
        TCPSender tcpSender = TCPSender(IP_LOOPBACK, TPCPORT_FOR_IMAGE_DATA);
        tcpSender.init_connection();
        tcpSender.send_packet(&imagePacket);
        tcpSender.close_connection();
        [self.queue waitUntilAllOperationsAreFinished];
        [self StartListeningForUDP: FLIGHT_NETWORK_PORT];
        [self StartListeningForTCP];

    }
}

- (void)StartListeningForTCP{
    ParseTCPOperation *parseTCP = [[ParseTCPOperation alloc] init];
    
    [self.queue addOperation:parseTCP];
    
    
    
    if([[self.queue operations] containsObject:parseTCP]){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(anyThread_handleImage:)
                                                     name:kReceiveAndParseImageDidFinish
                                                   object:nil];
    }
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

- (IBAction)PYASsaveImage_ButtonAction:(NSButton *)sender {
    
    NSData *imagedata;
    NSUInteger len;
    long xpixels, ypixels;
    NSBitmapImageRep *greyRep;
    unsigned char *pix;
    NSString *filenamePrefix;
    
    if ([[sender title] isEqualToString:@"Save PYAS-F"]) {
        filenamePrefix = @"PYASF";
        imagedata = self.PYASFcameraView.bkgImage;
        len = [self.PYASFcameraView.bkgImage length];
        
        xpixels = self.PYASFcameraView.imageXSize;
        ypixels = self.PYASFcameraView.imageYSize;
        
        greyRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:xpixels pixelsHigh:ypixels bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:xpixels bitsPerPixel:8];
        
        pix = [greyRep bitmapData];
        
        memcpy(pix, [self.PYASFcameraView.bkgImage bytes], len);
    }
    if ([[sender title] isEqualToString:@"Save PYAS-R"]) {
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
    
    DataPacket *packet = [notifData valueForKey:@"packet"];
    NSColor *FieldWasUpdatedColor = [NSColor blackColor];
    NSColor *FieldIsStaleColor = [NSColor darkGrayColor];
    
    Transform NorthTransform;
    double northAngle;
    //calculate the solar north angle here and pass it to
    
    timespec tspec;
    tspec.tv_sec = packet.frameSeconds;
    tspec.tv_nsec = packet.frameMilliseconds * 1e6;
    NorthTransform.calculate(tspec);
    northAngle = NorthTransform.getOrientation();
    //this code assumes that up on the screen is the zenith (which it is not)
    if (northAngle <= 180){  //should add a check for <0 degrees or >360 degrees
        northAngle = 180 - northAngle;
    }
    else {
        northAngle = 540 - northAngle;
    }
    
    if (packet.isSAS1) {
        [self.SAS1AutoFlipSwitch reset];
        [self.SAS1FrameNumberLabel setIntegerValue:[packet frameNumber]];
        [self.SAS1FrameTimeLabel setStringValue:[packet getframeTimeString]];
        
        [self.SAS1CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [packet commandKey]]];
        
        [[self.timeSeriesCollection objectForKey:@"SAS1 ctl X solution"] addPointWithTime:[packet getDate] :60*60*[packet.CTLCommand pointValue].x];
        [[self.timeSeriesCollection objectForKey:@"SAS1 ctl Y solution"] addPointWithTime:[packet getDate] :60*60*[packet.CTLCommand pointValue].y];
        //[[self.timeSeriesCollection objectForKey:@"SAS1 ctl R solution"] addPointWithTime:[packet getDate] :sqrtf(powf(60*60*[packet.CTLCommand pointValue].y,2) + powf(60*60*[packet.CTLCommand pointValue].y,2))];
        
        TimeSeries *ctlXValues = [self.timeSeriesCollection objectForKey:@"SAS1 ctl X solution"];
        TimeSeries *ctlYValues = [self.timeSeriesCollection objectForKey:@"SAS1 ctl Y solution"];
        
        //[[self.timeSeriesCollection objectForKey:@"SAS1 ctl R solution"] addPointWithTime:[packet getDate] :sqrtf(powf(60*60*[packet.CTLCommand pointValue].y,2) + powf(60*60*[packet.CTLCommand pointValue].y,2))];
        
        [self.PYASFCTLSigmaTextField setStringValue:[NSString stringWithFormat:@"%6.2f, %6.2f", ctlXValues.standardDeviation, ctlYValues.standardDeviation]];
        [self.PYASFCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [packet.CTLCommand pointValue].x, [packet.CTLCommand pointValue].y]];
        self.PYASFImageMaxTextField.intValue = packet.ImageMax;
        
        [self.PYASFcameraView setCircleCenter:[packet.sunCenter pointValue].x :[packet.sunCenter pointValue].y];
        self.PYASFcameraView.chordCrossingPoints = [packet getChordPoints];
        self.PYASFcameraView.fiducialPoints = [packet getFiducialPoints];
        self.PYASFcameraView.fiducialIDs = [packet getFiducialIDs];
        [self.PYASFcameraView setScreenCenter:[packet.screenCenter pointValue].x :[packet.screenCenter pointValue].y];
        self.PYASFcameraView.screenRadius = packet.screenRadius;
        self.PYASFcameraView.clockingAngle = packet.clockingAngle;
        
        [self.SAS1CPUTemperatureLabel setTextColor:FieldIsStaleColor];
        [self.PYASFCameraTemperatureLabel setTextColor:FieldIsStaleColor];
        [self.SAS1T0TextField setTextColor:FieldIsStaleColor];
        [self.SAS1T1TextField setTextColor:FieldIsStaleColor];
        [self.SAS1T2TextField setTextColor:FieldIsStaleColor];
        [self.SAS1T3TextField setTextColor:FieldIsStaleColor];
        [self.SAS1T4TextField setTextColor:FieldIsStaleColor];
        [self.SAS1T5TextField setTextColor:FieldIsStaleColor];

        [self.SAS1V0TextField setTextColor:FieldIsStaleColor];
        [self.SAS1V1TextField setTextColor:FieldIsStaleColor];
        [self.SAS1V2TextField setTextColor:FieldIsStaleColor];
        [self.SAS1V3TextField setTextColor:FieldIsStaleColor];
        [self.SAS1V4TextField setTextColor:FieldIsStaleColor];
        
        switch (packet.frameNumber % 8) {
            case 0:{
                NSString *string = [NSString stringWithFormat:@"%6.2f", packet.cpuTemperature];
                [self.SAS1CPUTemperatureLabel setStringValue:string];
                [self.SAS1CPUTemperatureLabel setTextColor:FieldWasUpdatedColor];
                
                [self.PYASFCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cameraTemperature]];
                if (packet.cameraTemperature != 0) {
                    [self.PYASFAutoFlipSwitch reset];
                }
                [self.PYASFCameraTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"PYAS-F camera temperature"] addPointWithTime:[packet getDate] :packet.cameraTemperature];
                break;}
            case 1:
                [self.PYASFCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cameraTemperature]];
                if (packet.cameraTemperature != 0) {
                    [self.PYASFAutoFlipSwitch reset];
                }
                [self.SAS1T0TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:0] floatValue]];
                [self.SAS1T0TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 2:
                [self.SAS1T1TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [self.SAS1V0TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:0] floatValue]];
                [self.SAS1T1TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS1V0TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 3:
                [self.SAS1T2TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [self.SAS1V1TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:1] floatValue]];
                [self.SAS1T2TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS1V1TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 4:
                [self.SAS1T3TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [self.SAS1V2TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:2] floatValue]];
                [self.SAS1T3TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS1V2TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 5:
                [self.SAS1T4TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [self.SAS1V3TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:3] floatValue]];
                [self.SAS1T4TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS1V3TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 6:
                [self.SAS1T5TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [self.SAS1V4TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:4] floatValue]];
                [self.SAS1T5TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS1V4TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 7:
                [self.SAS1ClockSync_indicator setIntValue:1*packet.isClockSynced];
                [self.SAS1isSavingImages setIntValue:1*packet.isSavingImages];
                break;
            default:
                break;
        }
        
        [self.PYASFAspectErrorCodeTextField setStringValue:packet.aspectErrorCode];
        [self.PYASFisTracking_indicator setIntValue:1*packet.isTracking];
        [self.PYASFProvidingCTL_indicator setIntValue:1*packet.isOutputting];
        [self.PYASFFoundSun_indicator setIntValue:1*packet.isSunFound];
        
        self.PYASFcameraView.northAngle = northAngle;
        
        NSString *writeString = [NSString stringWithFormat:@"%@, %@, %@, %@, %@, %@\n",
                                 self.SAS1FrameTimeLabel.stringValue,
                                 self.SAS1FrameNumberLabel.stringValue,
                                 self.PYASFCameraTemperatureLabel.stringValue,
                                 self.SAS1CPUTemperatureLabel.stringValue,
                                 [NSString stringWithFormat:@"%f, %f", [packet.sunCenter pointValue].x,
                                  [packet.sunCenter pointValue].y],
                                 [NSString stringWithFormat:@"%f, %f", [packet.CTLCommand pointValue].x,
                                  [packet.CTLCommand pointValue].y]
                                 ];
        [self.SAS1telemetrySaveFile writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Update the plot windows
        for (id key in self.PlotWindows) {
            [[self.PlotWindows objectForKey:key] update];
        }
        [self.PYASFcameraView draw];
    }
    
    if (packet.isSAS2) {
        [self.SAS2AutoFlipSwitch reset];
        [self.SAS2FrameNumberLabel setIntegerValue:[packet frameNumber]];
        [self.SAS2FrameTimeLabel setStringValue:[packet getframeTimeString]];
        [self.SAS2CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [packet commandKey]]];
        
        [self.PYASRCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [packet.CTLCommand pointValue].x, [packet.CTLCommand pointValue].y]];
        
        [self.PYASRcameraView setCircleCenter:[packet.sunCenter pointValue].x :[packet.sunCenter pointValue].y];
        self.PYASRcameraView.chordCrossingPoints = [packet getChordPoints];
        self.PYASRcameraView.fiducialPoints = [packet getFiducialPoints];
        [self.PYASRcameraView setScreenCenter:[packet.screenCenter pointValue].x :[packet.screenCenter pointValue].y];
        self.PYASRcameraView.screenRadius = packet.screenRadius;
        self.PYASRcameraView.clockingAngle = packet.clockingAngle;
        self.PYASRcameraView.fiducialIDs = [packet getFiducialIDs];
        
        if (packet.frameNumber % 2) {
            self.RASImageMaxTextField.intValue = packet.ImageMax;
        } else {
            self.PYASRImageMaxTextField.intValue = packet.ImageMax;
        }
        
        [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        [self.SAS1CPUTemperatureLabel setBackgroundColor:[NSColor whiteColor]];
        
        [[self.timeSeriesCollection objectForKey:@"SAS2 ctl X solution"] addPointWithTime:[packet getDate] :60*60*[packet.CTLCommand pointValue].x];
        [[self.timeSeriesCollection objectForKey:@"SAS2 ctl Y solution"] addPointWithTime:[packet getDate] :60*60*[packet.CTLCommand pointValue].y];
                
        TimeSeries *ctlXValues = [self.timeSeriesCollection objectForKey:@"SAS2 ctl X solution"];
        TimeSeries *ctlYValues = [self.timeSeriesCollection objectForKey:@"SAS2 ctl Y solution"];
        
        [self.PYASRCTLSigmaTextField setStringValue:[NSString stringWithFormat:@"%6.2f, %6.2f", ctlXValues.standardDeviation, ctlYValues.standardDeviation]];
        
        //[[self.timeSeriesCollection objectForKey:@"SAS2 ctl R solution"] addPointWithTime:[packet getDate] :sqrtf(powf(60*60*[packet.CTLCommand pointValue].y,2) + powf(60*60*[packet.CTLCommand pointValue].y,2))];
        
        [self.SAS2CPUTemperatureLabel setTextColor:FieldIsStaleColor];
        [self.PYASRCameraTemperatureLabel setTextColor:FieldIsStaleColor];
        [self.RASCameraTemperatureLabel setTextColor:FieldIsStaleColor];

        [self.SAS2T0TextField setTextColor:FieldIsStaleColor];
        [self.SAS2T1TextField setTextColor:FieldIsStaleColor];
        [self.SAS2T2TextField setTextColor:FieldIsStaleColor];
        [self.SAS2T3TextField setTextColor:FieldIsStaleColor];
        [self.SAS2T4TextField setTextColor:FieldIsStaleColor];
        [self.SAS2T5TextField setTextColor:FieldIsStaleColor];
        
        [self.SAS2V0TextField setTextColor:FieldIsStaleColor];
        [self.SAS2V1TextField setTextColor:FieldIsStaleColor];
        [self.SAS2V2TextField setTextColor:FieldIsStaleColor];
        [self.SAS2V3TextField setTextColor:FieldIsStaleColor];
        [self.SAS2V4TextField setTextColor:FieldIsStaleColor];
        
        switch (packet.frameNumber % 8) {
            case 0:
                [self.SAS2CPUTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cpuTemperature]];
                [self.PYASRCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cameraTemperature]];
                if (packet.cameraTemperature != 0) {
                    [self.PYASRAutoFlipSwitch reset];
                }
                [self.SAS2CPUTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [self.PYASRCameraTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"PYAS-R camera temperature"] addPointWithTime:[packet getDate] :packet.cameraTemperature];
                break;
            case 1:
                [[self.timeSeriesCollection objectForKey:@"RAS camera temperature"] addPointWithTime:[packet getDate] :packet.cameraTemperature];
                [self.RASCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cameraTemperature]];
                if (packet.cameraTemperature != 0) {
                    [self.RASAutoFlipSwitch reset];
                }
                [self.RASCameraTemperatureLabel setTextColor:FieldWasUpdatedColor]; 
                [self.SAS2T0TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:0] floatValue]];
                [self.SAS2T0TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 2:
                [self.SAS2T1TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [self.SAS2V0TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:0] floatValue]];
                [self.SAS2T1TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS2V0TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 3:
                [self.SAS2T2TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [self.SAS2V1TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:1] floatValue]];
                [self.SAS2T2TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS2V1TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 4:
                [self.SAS2T3TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [self.SAS2V2TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:2] floatValue]];
                [self.SAS2T3TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS2V2TextField setTextColor:[NSColor blackColor]];
                break;
            case 5:
                [self.SAS2T4TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [self.SAS2V3TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:3] floatValue]];
                [self.SAS2T4TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS2V3TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 6:
                [self.SAS2T5TextField setFloatValue:[[packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [self.SAS2V4TextField setFloatValue:[[packet.sbcVoltages objectAtIndex:4] floatValue]];
                [self.SAS2T5TextField setTextColor:FieldWasUpdatedColor];
                [self.SAS2V4TextField setTextColor:FieldWasUpdatedColor];
                break;
            case 7:
                [self.SAS2ClockSync_indicator setIntValue:1*packet.isClockSynced];
                [self.SAS2isSavingImages setIntValue:1*packet.isSavingImages];
                break;
            default:
                break;
        }

        
        //DataSeries *ctlYValues = [self.PYASRtimeSeriesCollection objectForKey:@"ctl X solution"];
        //DataSeries *ctlXValues = [self.PYASRtimeSeriesCollection objectForKey:@"ctl Y solution"];
        
        //[[self.PYASRtimeSeriesCollection objectForKey:@"time"] addObject:[packet getDate]];
        //[[self.PYASRtimeSeriesCollection objectForKey:@"cpu temperature"] addPoint:packet.cpuTemperature];
        //[[self.PYASRtimeSeriesCollection objectForKey:@"ctl X solution"] addPoint:60*60*[packet.CTLCommand pointValue].x];
        //[[self.PYASRtimeSeriesCollection objectForKey:@"ctl Y solution"] addPoint:60*60*[packet.CTLCommand pointValue].y];
        //[[self.PYASRtimeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([packet.CTLCommand pointValue].y - ctlXValues.average,2) + powf([packet.CTLCommand pointValue].y - ctlYValues.average,2))];
        
        self.PYASRcameraView.northAngle = northAngle;
        
        [self.PYASRAspectErrorCodeTextField setStringValue:packet.aspectErrorCode];
        [self.PYASRisTracking_indicator setIntValue:1*packet.isTracking];
        [self.PYASRProvidingCTL_indicator setIntValue:1*packet.isOutputting];
        [self.PYASRFoundSun_indicator setIntValue:1*packet.isSunFound];

        [self.PYASRcameraView draw];
        
        // Update the plot windows
        for (id key in self.PlotWindows) {
            [[self.PlotWindows objectForKey:key] update];
        }
    }

}

- (IBAction)OpenWindow_WindowMenuItemAction:(NSMenuItem *)sender {
    NSString *userChoice = [sender title];
    
    if ([userChoice isEqual: @"Console"]) {
        [self.Console_window showWindow:nil];
    }
    if ([self.PlotWindowsAvailable containsObject:userChoice]) {
        if ([self.PlotWindows objectForKey:userChoice] == nil) {
            if ([userChoice isEqualToString:@"camera temperature"]) {
                //NSDictionary *PYASFData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.PYASFtimeSeriesCollection objectForKey:@"time"], @"time", [self.PYASFtimeSeriesCollection objectForKey:userChoice], @"y", nil];
                //NSDictionary *PYASRData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.PYASRtimeSeriesCollection objectForKey:@"time"], @"time", [self.PYASRtimeSeriesCollection objectForKey:userChoice], @"y", nil];
                //NSDictionary *RASData = [[NSDictionary alloc] initWithObjectsAndKeys:[self.RAStimeSeriesCollection objectForKey:@"time"], @"time", [self.RAStimeSeriesCollection objectForKey:userChoice], @"y", nil];
                NSArray *objs = [NSArray arrayWithObjects:[self.timeSeriesCollection objectForKey:@"PYAS-F camera temperature"], [self.timeSeriesCollection objectForKey:@"PYAS-R camera temperature"], [self.timeSeriesCollection objectForKey:@"RAS camera temperature"] ,nil];
                NSArray *keys = [NSArray arrayWithObjects:@"PYAS-F", @"PYAS-R", @"RAS", nil];
                NSDictionary *data = [[NSDictionary alloc] initWithObjects:objs forKeys:keys];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"ctl X solution"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS1 ctl X solution"], @"PYAS-F",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 ctl X solution"] , @"PYAS-R", nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"ctl Y solution"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS1 ctl Y solution"], @"PYAS-F",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 ctl Y solution"] , @"PYAS-R", nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"ctl R solution"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS1 ctl R solution"], @"PYAS-F",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 ctl R solution"] , @"PYAS-R", nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"cpu temperature"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS1 cpu temperature"], @"SAS-2",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 cpu temperature"] , @"SAS-1", nil];
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
        self.PYASFcameraView.imageExists = NO;
    }
    if ([[sender title] isEqualToString:@"Clear PYAS-R Image"]) {
        self.PYASRcameraView.bkgImage = nil;
        self.PYASRcameraView.imageExists = NO;
    }
}

- (IBAction)RunTest:(id)sender {
//    int xpixels = 1296;
//    int ypixels = 966;
//    NSUInteger len = xpixels * ypixels;
//    Byte *pixels = (Byte *)malloc(len);
//    for (int ix = 0; ix < xpixels; ix++) {
//        for (int iy = 0; iy < ypixels; iy++) {
//            pixels[ix + iy*xpixels] = pow(pow(ix - xpixels/2.0,2) + pow(iy - ypixels/2.0,2),0.5)/1616.0 * 255;
//        }
//    }
//    
//    NSData *data = [NSData dataWithBytes:pixels length:sizeof(uint8_t) * xpixels * ypixels];
//    
//    self.PYASFcameraView.bkgImage = data;
//    self.PYASFcameraView.imageXSize = xpixels;
//    self.PYASFcameraView.imageYSize = ypixels;
//    self.PYASFcameraView.imageExists = YES;
//    self.PYASFcameraView.turnOnBkgImage = YES;
//    [self.PYASFcameraView draw];
//    
//    [self postToLogWindow:@"test string"];
//    free(pixels);
//    [self.PYASFCameraTemperatureLabel setIntegerValue:-30];
//    [self.PYASRCameraTemperatureLabel setIntegerValue:-30];
//    [self.SAS1CPUTemperatureLabel setIntegerValue:100];
//    
    //DataSeries *PYASFcamTemp = [self.PYASFtimeSeriesCollection objectForKey:@"camera temperature"];
    //DataSeries *PYASRcamTemp = [self.PYASRtimeSeriesCollection objectForKey:@"camera temperature"];
    //DataSeries *RAScamTemp = [self.RAStimeSeriesCollection objectForKey:@"camera temperature"];
    //for (int i = 0; i < 10; i++) {
        //NSDate *currentDate = [NSDate date];
       // [[self.PYASFtimeSeriesCollection objectForKey:@"time"] addObject:[NSDate dateWithTimeInterval:i sinceDate:[NSDate date]]];
        //[PYASFcamTemp addPoint:(float)rand()/RAND_MAX * 5];
        //[PYASRcamTemp addPoint:(float)rand()/RAND_MAX * 5];
        //[RAScamTemp addPoint:(float)rand()/RAND_MAX * 5];
   // }
    
    for (int i = 0; i < 1000; i++) {
        float temp = 10 * (float)rand()/RAND_MAX + 20.0;
        NSDate *time = [NSDate dateWithTimeInterval:i sinceDate:[NSDate date]];
        [[self.timeSeriesCollection objectForKey:@"PYAS-R camera temperature"] addPointWithTime:time :temp];
        [[self.timeSeriesCollection objectForKey:@"PYAS-F camera temperature"] addPointWithTime:time :temp+10];
        [[self.timeSeriesCollection objectForKey:@"RAS camera temperature"] addPointWithTime:time :temp+15];
    }
    NSLog(@"test");
    // Update the plot windows
    for (id key in self.PlotWindows) {
        [[self.PlotWindows objectForKey:key] update];
    }
}

@end
