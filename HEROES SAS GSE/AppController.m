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
- (NSFileHandle *)OpenTelemetrySaveTextFiles: (NSString *)filename_prefix;
- (void)StartListeningForUDP: (int)port;
- (void)StartListeningForTCP;
- (void)updateTelemetrySaveFile: (NSFileHandle *)fileHandle :(DataPacket *)packet;
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

@synthesize SAS1MissedFrameCount;
@synthesize SAS2MissedFrameCount;

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
        
        self.PlotWindowsAvailable = [NSArray arrayWithObjects:@"camera temperature", @"sas-1 temperatures", @"sas-2 temperatures", @"sas-1 voltages", @"sas-2 voltages", @"ctl X solution", @"ctl Y solution", @"ctl R solution", nil];
        
        //NSArray *systemNames = [[NSArray alloc] initWithObjects:@"SAS-1", @"SAS-2", nil];
        //NSArray *cameraNames = [[NSArray alloc] initWithObjects:@"PYAS-F", "PYAS-R", "RAS", nil];
        //NSArray *data = [NSArray arrayWithObjects:@"camera temperature", @"cpu temperature", @"ctl X solution", @"ctl Y solution", nil];

        self.timeSeriesCollection = [[NSDictionary alloc] init];

        NSArray *timeSeriesNames = [NSArray arrayWithObjects:@"SAS1 cpu temperature", @"SAS2 cpu temperature", @"PYAS-F camera temperature", @"PYAS-R camera temperature", @"RAS camera temperature", @"SAS1 ctl X solution", @"SAS1 ctl Y solution", @"SAS1 ctl R solution", @"SAS2 ctl X solution", @"SAS2 ctl Y solution", @"SAS2 ctl R solution", @"SAS1 cpuheatsink temperature", @"SAS2 cpuheatsink temperature", @"SAS1 hdd temperature", @"SAS2 hdd temperature", @"SAS1 heater plate temperature", @"SAS2 heater plate temperature", @"SAS1 can temperature", @"SAS2 can temperature", @"SAS1 air temperature", @"SAS2 air temperature", @"SAS1 rail temperature", @"SAS2 rail temperature", @"SAS1 1.05V", @"SAS2 1.05V", @"SAS1 5.0V", @"SAS2 5.0V", @"SAS1 12.0V", @"SAS2 12.0V", @"SAS1 3.3V", @"SAS2 3.3V", @"SAS1 2.5V", @"SAS2 2.5V", nil];
        
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
    
    formatter = [self.SAS1CPUHeatSinkTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1CanTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1HDDTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1HeaterPlateTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1AirTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS1RailTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    
    formatter = [self.SAS2CPUHeatSinkTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2CanTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2HDDTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2HeaterPlateTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2AirTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    formatter = [self.SAS2RailTemp formatter];
    formatter.maximum = 100;
    formatter.minimum = -20;
    
    formatter = [self.SAS1V1p05Voltage formatter];
    formatter.maximum = 1.05 * 1.2;
    formatter.minimum = 0.80;
    [self.SAS1V1p05Voltage setFormatter:formatter];
    formatter = [self.SAS2V1p05Voltage formatter];
    formatter.maximum = 1.05 * 1.20;
    formatter.minimum = 0.80;
    
    formatter = [self.PYASFImageMaxTextField formatter];
    formatter.maximum = 220;
    formatter.minimum = 75;
    
    formatter = [self.PYASRImageMaxTextField formatter];
    formatter.maximum = 220;
    formatter.minimum = 75;
    
    formatter = [self.RASImageMaxTextField formatter];
    formatter.maximum = 220;
    formatter.minimum = 75;
    
    formatter = [self.SAS1V2p5Voltage formatter];
    formatter.maximum = 2.5 * 1.20;
    formatter.minimum = 2.5 * 0.80;
    formatter = [self.SAS2V2p5Voltage formatter];
    formatter.maximum = 2.5 * 1.20;
    formatter.minimum = 2.5 * 0.80;
    
    formatter = [self.SAS1V3p3Voltage formatter];
    formatter.maximum = 3.3 * 1.20;
    formatter.minimum = 3.3 * 0.80;
    formatter = [self.SAS2V3p3Voltage formatter];
    formatter.maximum = 3.3 * 1.20;
    formatter.minimum = 3.3 * 0.80;
    
    formatter = [self.SAS1V5Votlage formatter];
    formatter.maximum = 5.0 * 1.20;
    formatter.minimum = 5.0 * 0.80;
    formatter = [self.SAS2V5Votlage formatter];
    formatter.maximum = 5.0 * 1.20;
    formatter.minimum = 5.0 * 0.80;
    
    formatter = [self.SAS1V12Voltage formatter];
    formatter.maximum = 12.0 * 1.20;
    formatter.minimum = 12.0 * 0.80;
    formatter = [self.SAS2V12Voltage formatter];
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
    
    [self postToLogWindow:@"Application started"];
    self.SAS1telemetrySaveFile = [self OpenTelemetrySaveTextFiles: @"HEROES_SAS1"];
    self.SAS2telemetrySaveFile = [self OpenTelemetrySaveTextFiles: @"HEROES_SAS2"];
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

- (IBAction)ConsoleSurpressACKToggle:(NSButton *)sender {
    self.Console_window.surpressACK = ([sender state] == NSOnState);
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

- (NSFileHandle *)OpenTelemetrySaveTextFiles: (NSString *)filename_prefix{
    // Open a file to save the telemetry stream to
    // The file is a csv file
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"%@_tmlog_%@.txt", filename_prefix, [self createDateTimeString:@"file"]];
    
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    // open file to save data stream
    NSFileHandle *theFileHandle = [NSFileHandle fileHandleForWritingAtPath: filePath ];
    if (theFileHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        theFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    //say to handle where's the file fo write
    [theFileHandle truncateFileAtOffset:[self.SAS1telemetrySaveFile seekToEndOfFile]];
    NSString *writeString = [NSString stringWithFormat:@"%@ Telemetry Log File %@\n", [filename_prefix stringByReplacingOccurrencesOfString:@"_" withString:@" "], [self createDateTimeString:nil]];
    //position handle cursor to the end of file
    [theFileHandle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    writeString = [NSString stringWithFormat:@"time, frame, cpuTemp, pyasTemp, canTemp, airTemp, railTemp, hddTemp, heaterTemp, volt1, volt2, volt3, volt4, sunX, sunY, screenX, screenY, screenRadius, ctlX, ctlY, pyasMax"];
    [theFileHandle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    [self postToLogWindow:[NSString stringWithFormat:@"Opening file %@", filename]];
    return theFileHandle;
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
    
    timespec tspec;
    tspec.tv_sec = packet.frameSeconds;
    tspec.tv_nsec = packet.frameMilliseconds * 1e6;
    NorthTransform.calculate(tspec);
    northAngle = packet.clockingAngle+NorthTransform.getOrientation();
    
    NSArray *CTLDegMinSecX = [self convertDegreesToDegMinSec:[packet.CTLCommand pointValue].x];
    NSArray *CTLDegMinSecY = [self convertDegreesToDegMinSec:[packet.CTLCommand pointValue].y];

    NSString *CTLString = [NSString stringWithFormat:@"%3.0f°%2.0f' %4.2f'',%3.0f°%2.0f' %4.2f'' ", [[CTLDegMinSecX objectAtIndex:0] floatValue],
                           [[CTLDegMinSecX objectAtIndex:1] floatValue], [[CTLDegMinSecX objectAtIndex:2] floatValue], [[CTLDegMinSecY objectAtIndex:0] floatValue], [[CTLDegMinSecY objectAtIndex:1] floatValue], [[CTLDegMinSecY objectAtIndex:2] floatValue]];
    if (packet.isSAS1) {
        [self.SAS1AutoFlipSwitch reset];
        
        NSUInteger lastFrameNumber = [self.SAS1FrameNumberLabel integerValue];
        if (([packet frameNumber] - lastFrameNumber) != 1) {
            self.SAS1MissedFrameCount++;
            [self.SAS1DroppedFrameTextField setIntegerValue:self.SAS1MissedFrameCount];
        }
        
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
                
        [self.PYASFCTLCmdEchoTextField setStringValue:CTLString];
        
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
        [self.SAS1CPUHeatSinkTemp setTextColor:FieldIsStaleColor];
        [self.SAS1CanTemp setTextColor:FieldIsStaleColor];
        [self.SAS1HDDTemp setTextColor:FieldIsStaleColor];
        [self.SAS1HeaterPlateTemp setTextColor:FieldIsStaleColor];
        [self.SAS1AirTemp setTextColor:FieldIsStaleColor];
        [self.SAS1RailTemp setTextColor:FieldIsStaleColor];

        [self.SAS1V1p05Voltage setTextColor:FieldIsStaleColor];
        [self.SAS1V2p5Voltage setTextColor:FieldIsStaleColor];
        [self.SAS1V3p3Voltage setTextColor:FieldIsStaleColor];
        [self.SAS1V5Votlage setTextColor:FieldIsStaleColor];
        [self.SAS1V12Voltage setTextColor:FieldIsStaleColor];
        
        switch (packet.frameNumber % 8) {
            case 0:{
                NSString *string = [NSString stringWithFormat:@"%6.2f", packet.cpuTemperature];
                [self.SAS1CPUTemperatureLabel setStringValue:string];
                [self.SAS1CPUTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 cpu temperature"] addPointWithTime:[packet getDate] :packet.cpuTemperature];
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
                [self.SAS1CPUHeatSinkTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:0] floatValue]];
                [self.SAS1CPUHeatSinkTemp setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 cpuheatsink temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:0] floatValue]];
                break;
            case 2:
                [self.SAS1CanTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [self.SAS1V1p05Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:0] floatValue]];
                [self.SAS1CanTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS1V1p05Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 can temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS1 1.05V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:0] floatValue]];
                break;
            case 3:
                [self.SAS1HDDTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [self.SAS1V2p5Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:1] floatValue]];
                [self.SAS1HDDTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS1V2p5Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 hdd temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS1 2.5V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:1] floatValue]];
                break;
            case 4:
                [self.SAS1HeaterPlateTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [self.SAS1V3p3Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:2] floatValue]];
                [self.SAS1HeaterPlateTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS1V3p3Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 heater plate temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS1 3.3V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:2] floatValue]];
                break;
            case 5:
                [self.SAS1AirTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [self.SAS1V5Votlage setFloatValue:[[packet.sbcVoltages objectAtIndex:3] floatValue]];
                [self.SAS1AirTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS1V5Votlage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 air temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS1 5.0V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:3] floatValue]];
                break;
            case 6:
                [self.SAS1RailTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [self.SAS1V12Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:4] floatValue]];
                [self.SAS1RailTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS1V12Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS1 rail temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS1 12.0V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:4] floatValue]];
                break;
            case 7:
                [self.SAS1ClockSync_indicator setIntValue:1*packet.isClockSynced];
                [self.SAS1isPYASSavingImages setIntValue:1*packet.isPYASSavingImages];
                break;
            default:
                break;
        }

        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:packet.aspectErrorCode];
        if ([packet.aspectErrorCode isNotEqualTo:@"No error"]) {
            NSDictionary *firstAttributes = @{NSForegroundColorAttributeName: [NSColor redColor]};
            [attrString addAttributes:firstAttributes range:NSMakeRange(0, [packet.aspectErrorCode length])];
        } else {
            NSDictionary *firstAttributes = @{NSForegroundColorAttributeName: [NSColor blackColor]};
            [attrString addAttributes:firstAttributes range:NSMakeRange(0, [packet.aspectErrorCode length])];
        }
        
        [self.PYASFAspectErrorCodeTextField setAttributedStringValue:attrString];
        [self.PYASFisTracking_indicator setIntValue:packet.isTracking];
        [self.PYASFProvidingCTL_indicator setIntValue:packet.isOutputting];
        [self.SAS1ReceivingGPS_indicator setIntValue:packet.isReceivingGPS];

        self.PYASFcameraView.northAngle = northAngle;
        
        [self updateTelemetrySaveFile: self.SAS1telemetrySaveFile: packet];
        // Update the plot windows
        for (id key in self.PlotWindows) {
            [[self.PlotWindows objectForKey:key] update];
        }
        [self.PYASFcameraView draw];
    }
    
    if (packet.isSAS2) {
        [self.SAS2AutoFlipSwitch reset];
        
        NSUInteger lastFrameNumber = [self.SAS2FrameNumberLabel integerValue];
        if (([packet frameNumber] - lastFrameNumber) != 1) {
            self.SAS2MissedFrameCount++;
            [self.SAS2DroppedFrameTextField setIntegerValue:self.SAS2MissedFrameCount];
        }
        
        [self.SAS2FrameNumberLabel setIntegerValue:[packet frameNumber]];
        
        [self.SAS2FrameTimeLabel setStringValue:[packet getframeTimeString]];
        [self.SAS2CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [packet commandKey]]];
        
        [self.PYASRCTLCmdEchoTextField setStringValue:CTLString];

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

        [self.SAS2CPUHeatSinkTemp setTextColor:FieldIsStaleColor];
        [self.SAS2CanTemp setTextColor:FieldIsStaleColor];
        [self.SAS2HDDTemp setTextColor:FieldIsStaleColor];
        [self.SAS2HeaterPlateTemp setTextColor:FieldIsStaleColor];
        [self.SAS2AirTemp setTextColor:FieldIsStaleColor];
        [self.SAS2RailTemp setTextColor:FieldIsStaleColor];
        
        [self.SAS2V1p05Voltage setTextColor:FieldIsStaleColor];
        [self.SAS2V2p5Voltage setTextColor:FieldIsStaleColor];
        [self.SAS2V3p3Voltage setTextColor:FieldIsStaleColor];
        [self.SAS2V5Votlage setTextColor:FieldIsStaleColor];
        [self.SAS2V12Voltage setTextColor:FieldIsStaleColor];
        
        switch (packet.frameNumber % 8) {
            case 0:
                [self.SAS2CPUTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cpuTemperature]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 cpu temperature"] addPointWithTime:[packet getDate] :packet.cpuTemperature];
                [self.PYASRCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cameraTemperature]];
                if (packet.cameraTemperature != 0) {
                    [self.PYASRAutoFlipSwitch reset];
                }
                [self.SAS2CPUTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [self.PYASRCameraTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"PYAS-R camera temperature"] addPointWithTime:[packet getDate] :packet.cameraTemperature];
                break;
            case 1:
                [self.RASCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", packet.cameraTemperature]];
                if (packet.cameraTemperature != 0) {
                    [self.RASAutoFlipSwitch reset];
                }
                [self.RASCameraTemperatureLabel setTextColor:FieldWasUpdatedColor];
                [self.SAS2CPUHeatSinkTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS2CPUHeatSinkTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:0] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"RAS camera temperature"] addPointWithTime:[packet getDate] :packet.cameraTemperature];
                [[self.timeSeriesCollection objectForKey:@"SAS2 cpuheatsink temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:0] floatValue]];
                break;
            case 2:
                [self.SAS2CanTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [self.SAS2V1p05Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:0] floatValue]];
                [self.SAS2CanTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS2V1p05Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS2 can temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:1] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 1.05V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:0] floatValue]];
                break;
            case 3:
                [self.SAS2HDDTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [self.SAS2V2p5Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:1] floatValue]];
                [self.SAS2HDDTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS2V2p5Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS2 hdd temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:2] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 2.5V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:1] floatValue]];
                break;
            case 4:
                [self.SAS2HeaterPlateTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [self.SAS2V3p3Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:2] floatValue]];
                [self.SAS2HeaterPlateTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS2V3p3Voltage setTextColor:[NSColor blackColor]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 heater plate temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:3] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 3.3V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:2] floatValue]];
                break;
            case 5:
                [self.SAS2AirTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [self.SAS2V5Votlage setFloatValue:[[packet.sbcVoltages objectAtIndex:3] floatValue]];
                [self.SAS2AirTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS2V5Votlage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS2 air temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:4] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 5.0V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:3] floatValue]];
                break;
            case 6:
                [self.SAS2RailTemp setFloatValue:[[packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [self.SAS2V12Voltage setFloatValue:[[packet.sbcVoltages objectAtIndex:4] floatValue]];
                [self.SAS2RailTemp setTextColor:FieldWasUpdatedColor];
                [self.SAS2V12Voltage setTextColor:FieldWasUpdatedColor];
                [[self.timeSeriesCollection objectForKey:@"SAS2 rail temperature"] addPointWithTime:[packet getDate] :[[packet.i2cTemperatures objectAtIndex:5] floatValue]];
                [[self.timeSeriesCollection objectForKey:@"SAS2 12.0V"] addPointWithTime:[packet getDate] :[[packet.sbcVoltages objectAtIndex:4] floatValue]];
                break;
            case 7:
                [self.SAS2ClockSync_indicator setIntValue:packet.isClockSynced];
                [self.SAS2isPYASSavingImages setIntValue:packet.isPYASSavingImages];
                [self.SAS2isRASSavingImages setIntValue:packet.isRASSavingImages];
                break;
            default:
                break;
        }

        self.PYASRcameraView.northAngle = northAngle;
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:packet.aspectErrorCode];
        if ([packet.aspectErrorCode isNotEqualTo:@"No error"]) {
            NSDictionary *firstAttributes = @{NSForegroundColorAttributeName: [NSColor redColor]};
            [attrString addAttributes:firstAttributes range:NSMakeRange(0, [packet.aspectErrorCode length])];
        } else {
            NSDictionary *firstAttributes = @{NSForegroundColorAttributeName: [NSColor blackColor]};
            [attrString addAttributes:firstAttributes range:NSMakeRange(0, [packet.aspectErrorCode length])];
        }
        
        [self.PYASRAspectErrorCodeTextField setAttributedStringValue:attrString];
        [self.PYASRisTracking_indicator setIntValue:packet.isTracking];
        [self.PYASRProvidingCTL_indicator setIntValue:packet.isOutputting];
        [self.SAS2ReceivingGPS_indicator setIntValue:packet.isReceivingGPS];

        [self.PYASRcameraView draw];
    
        [self updateTelemetrySaveFile: self.SAS2telemetrySaveFile: packet];
                
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
            if ([userChoice isEqualToString:@"sas-1 temperatures"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS1 cpu temperature"], @"cpu",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 cpuheatsink temperature"] , @"heat sink",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 can temperature"] , @"can",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 hdd temperature"] , @"hdd",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 heater plate temperature"] , @"heater",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 air temperature"] , @"air",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 rail temperature"] , @"rail",
                                      nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"sas-2 temperatures"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS2 cpu temperature"], @"cpu",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 cpuheatsink temperature"] , @"heat sink",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 can temperature"] , @"can",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 hdd temperature"] , @"hdd",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 heater plate temperature"] , @"heater",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 air temperature"] , @"air",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 rail temperature"] , @"rail",
                                      nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"sas-1 voltages"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS1 1.05V"], @"1.05V",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 2.5V"] , @"2.5V",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 3.3V"] , @"3.3V",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 5.0V"] , @"5.0V",
                                      [self.timeSeriesCollection objectForKey:@"SAS1 12.0V"] , @"12.0V",
                                      nil];
                PlotWindowController *newPlotWindow = [[PlotWindowController alloc] initWithData:data];
                [newPlotWindow showWindow:self];
                [self.PlotWindows setObject:newPlotWindow forKey:userChoice];
            }
            if ([userChoice isEqualToString:@"sas-2 voltages"]) {
                NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [self.timeSeriesCollection objectForKey:@"SAS2 1.05V"], @"1.05V",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 2.5V"] , @"2.5V",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 3.3V"] , @"3.3V",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 5.0V"] , @"5.0V",
                                      [self.timeSeriesCollection objectForKey:@"SAS2 12.0V"] , @"12.0V",
                                      nil];
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

- (void)updateTelemetrySaveFile: (NSFileHandle *)fileHandle :(DataPacket *)packet{
    
    NSString *writeString = [NSString stringWithFormat:@"%@,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d\n",
                             [packet getframeTimeString],
                             [packet frameNumber],
                             ([packet isSAS1] ? [self.SAS1CPUTemperatureLabel floatValue] : [self.SAS2CPUTemperatureLabel floatValue]),
                             ([packet isSAS1] ? [self.PYASFCameraTemperatureLabel floatValue] : [self.PYASRCameraTemperatureLabel floatValue]),
                             ([packet isSAS1] ? [self.SAS1CanTemp floatValue] : [self.SAS2CanTemp floatValue]),
                             ([packet isSAS1] ? [self.SAS1AirTemp floatValue] : [self.SAS2AirTemp floatValue]),
                             ([packet isSAS1] ? [self.SAS1RailTemp floatValue] : [self.SAS2RailTemp floatValue]),
                             ([packet isSAS1] ? [self.SAS1HDDTemp floatValue] : [self.SAS2HDDTemp floatValue]),
                             ([packet isSAS1] ? [self.SAS1HeaterPlateTemp floatValue] : [self.SAS2HeaterPlateTemp floatValue]),
                             ([packet isSAS1] ? [self.SAS1V1p05Voltage floatValue] : [self.SAS2V1p05Voltage floatValue]),
                             ([packet isSAS1] ? [self.SAS1V2p5Voltage floatValue] : [self.SAS2V2p5Voltage floatValue]),
                             ([packet isSAS1] ? [self.SAS1V5Votlage floatValue] : [self.SAS2V5Votlage floatValue]),
                             ([packet isSAS1] ? [self.SAS1V12Voltage floatValue] : [self.SAS2V12Voltage floatValue]),
                             [packet.sunCenter pointValue].x,
                             [packet.sunCenter pointValue].y,
                             [packet.screenCenter pointValue].x,
                             [packet.screenCenter pointValue].y,
                             packet.screenRadius,
                             [packet.CTLCommand pointValue].x,
                             [packet.CTLCommand pointValue].y,
                             ([packet isSAS1] ? [self.PYASFImageMaxTextField intValue] : [self.PYASRImageMaxTextField intValue])];
    [fileHandle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
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
}

- (NSArray *)convertDegreesToDegMinSec: (float)value{
    float degrees, minutes, seconds;
    degrees = ((value < 0) ? -1 : 1) * floorf(abs(value));
    minutes = floorf((fabs(value) - fabs(degrees)) * 60.0);
    seconds = (fabs(value) - fabs(degrees) - minutes/60.0) * 60.0 * 60.0;
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:degrees], [NSNumber numberWithFloat:minutes], [NSNumber numberWithFloat:seconds], nil];
}

@end
