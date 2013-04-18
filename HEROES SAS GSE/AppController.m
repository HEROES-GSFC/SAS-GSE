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
- (NSString *)createDateTimeString: (NSString *)type;
- (void)OpenTelemetrySaveTextFiles;
@end

@implementation AppController

// GUI Elements
@synthesize RunningIndicator;
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
@synthesize SaveData_checkbox;

@synthesize StartStopSegmentedControl;
@synthesize SAS1CmdCountTextField;
@synthesize SAS1CmdKeyTextField;
@synthesize PYASFImageMaxMinTextField;
@synthesize MainWindow;
@synthesize PYASFcameraView = _PYASFcameraView;
@synthesize PYASRcameraView = _PYASRcameraView;
@synthesize Commander_window = _Commander_window;
@synthesize Console_window = _Console_window;
@synthesize Plot_window = _Plot_window;

@synthesize timer = _timer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize packet = _packet;
@synthesize SAS1telemetrySaveFile = _SAS1telemetrySaveFile;
@synthesize SAS2telemetrySaveFile = _SAS2telemetrySaveFile;
@synthesize timeSeriesCollection = _timeSeriesCollection;

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
        
        DataSeries *cameraTemperature = [[DataSeries alloc] init];
        DataSeries *ctlSolutionX = [[DataSeries alloc] init];
        DataSeries *ctlSolutionY = [[DataSeries alloc] init];
        DataSeries *ctlSolutionR = [[DataSeries alloc] init];
        cameraTemperature.name = @"Camera Temperature";
        ctlSolutionX.name = @"CTL X Solution ";
        ctlSolutionY.name = @"CTL Y Solution";
        ctlSolutionR.name = @"CTL R Solution";
        
        NSMutableArray *time = [[NSMutableArray alloc] init];
        NSArray *objects = [NSArray arrayWithObjects:time, cameraTemperature, ctlSolutionX, ctlSolutionY, ctlSolutionR, nil];
        NSArray *keys = [NSArray arrayWithObjects:@"time", @"camera temperature", @"ctl X solution", @"ctl Y solution", @"ctl R solution", nil];
        self.timeSeriesCollection = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        
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

- (CommanderWindowController *)Commander_window
{
    if (_Commander_window == nil)
    {
        _Commander_window = [[CommanderWindowController alloc] init];
    }
    return _Commander_window;
}
- (NSDictionary *)timeSeriesCollection
{
    if (_timeSeriesCollection == nil)
    {
        _timeSeriesCollection = [[NSDictionary alloc] init];
    }
    return _timeSeriesCollection;
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

- (IBAction)StartStopButtonAction:(id)sender {
    if ([StartStopSegmentedControl selectedSegment] == 0) {
        
        [self.queue cancelAllOperations];
        
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

            [self.RunningIndicator setHidden:NO];
            [self.RunningIndicator startAnimation:self];
        }
        
        if([[self.queue operations] containsObject:parseTCP]){
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(anyThread_handleImage:)
                                                         name:kReceiveAndParseImageDidFinish
                                                       object:nil];
        }
        
        if ([self.SaveData_checkbox state] == NSOnState) {
            [self OpenTelemetrySaveTextFiles];
        }
    }
    if ([StartStopSegmentedControl selectedSegment] == 1) {
        [self.queue cancelAllOperations];
        [self.RunningIndicator setHidden:YES];
        [self.RunningIndicator stopAnimation:self];
        [self.SAS1telemetrySaveFile closeFile];
        [self.SAS2telemetrySaveFile closeFile];
    }
}


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
    
    NSRange CameraOKTempRange = NSMakeRange(-20, 60);
    NSRange CPUOKTempRange = NSMakeRange(-20, 60);
    
    if (self.packet.isSAS1) {
     
        [self.SAS1FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
        [self.SAS1FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
        [self.SAS1CmdCountTextField setIntegerValue:[self.packet commandCount]];
        [self.SAS1CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];

        [[self.timeSeriesCollection objectForKey:@"time"] addObject:[NSDate dateWithNaturalLanguageString:[self.packet getframeTimeString]]];
        [[self.timeSeriesCollection objectForKey:@"camera temperature"] addPoint:self.packet.cameraTemperature];
        [[self.timeSeriesCollection objectForKey:@"ctl X solution"] addPoint:[self.packet.CTLCommand pointValue].x];
        [[self.timeSeriesCollection objectForKey:@"ctl Y solution"] addPoint:[self.packet.CTLCommand pointValue].y];
        [[self.timeSeriesCollection objectForKey:@"ctl R solution"] addPoint:sqrtf(powf([self.packet.CTLCommand pointValue].y,2) + powf([self.packet.CTLCommand pointValue].y,2))];

        DataSeries *cameraTemps = [self.timeSeriesCollection objectForKey:@"camera temperature"];
        DataSeries *ctlYValues = [self.timeSeriesCollection objectForKey:@"ctl X solution"];
        DataSeries *ctlXValues = [self.timeSeriesCollection objectForKey:@"ctl Y solution"];
        DataSeries *ctlRValues = [self.timeSeriesCollection objectForKey:@"ctl R solution"];

        [self.PYASFCameraTemperatureLabel setStringValue:[NSString stringWithFormat:@"%6.2f", self.packet.cameraTemperature]];
        [self.PYASFCTLSigmaTextField setStringValue:[NSString stringWithFormat:@"%6.2f, %6.2f", ctlXValues.standardDeviation, ctlYValues.standardDeviation]];
               
        self.Plot_window.y = ctlRValues;
        [self.Plot_window update];
        //[self.PYASFCameraTemperatureLabel setFloatValue:self.packet.cameraTemperature];
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

        //calculate the solar north angle here and pass it to PYASFcameraView
        
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
        
        [self.PYASRcameraView draw];
    }
    
}

- (IBAction)OpenWindow_WindowMenuItemAction:(NSMenuItem *)sender {
    NSString *userChoice = [sender title];
    
    if ([userChoice isEqual: @"Commander"]) {
        [self.Commander_window showWindow:nil];
        [self.Plot_window showWindow:nil];
    }
    if ([userChoice isEqual: @"Console"]) {
        [self.Console_window showWindow:nil];
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
