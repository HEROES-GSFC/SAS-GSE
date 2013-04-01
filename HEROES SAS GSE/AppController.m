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

@interface AppController ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDictionary *listOfCommands;
@property (nonatomic, strong) DataPacket *packet;
- (NSString *)createDateTimeString: (NSString *)type;
- (void)OpenTelemetrySaveFiles;
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

@synthesize StartStopSegmentedControl;
@synthesize SAS1CmdCountTextField;
@synthesize SAS1CmdKeyTextField;
@synthesize PYASFImageMaxMinTextField;
@synthesize PYASFdrawBkgImage_checkbox;
@synthesize PYASFcameraView = _PYASFcameraView;
@synthesize PYASRcameraView = _PYASRcameraView;
@synthesize Commander_window = _Commander_window;
@synthesize Console_window = _Console_window;

@synthesize timer = _timer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize packet = _packet;
@synthesize SAS1telemetrySaveFile = _SAS1telemetrySaveFile;
@synthesize SAS2telemetrySaveFile = _SAS2telemetrySaveFile;

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


- (IBAction)bkgImageIsClicked:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        self.PYASFcameraView.turnOnBkgImage = TRUE;}
    if ([sender state] == NSOffState){
        self.PYASFcameraView.turnOnBkgImage = FALSE;}
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
        
        
    [self OpenTelemetrySaveFiles];
    }
    if ([StartStopSegmentedControl selectedSegment] == 1) {
        [self.queue cancelAllOperations];
        [self.RunningIndicator setHidden:YES];
        [self.RunningIndicator stopAnimation:self];
        [self.SAS1telemetrySaveFile closeFile];
        [self.SAS2telemetrySaveFile closeFile];
    }
}

- (void)OpenTelemetrySaveFiles{
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
}

- (IBAction)saveImage_ButtonAction:(NSButton *)sender {
    
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

// -------------------------------------------------------------------------------
//	anyThread_handleData:note
//
//	This method is called from any possible thread (any NSOperation) used to
//	update our table view and its data source.
//
//	The notification contains an NSDictionary
// -------------------------------------------------------------------------------
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
    self.PYASFcameraView.bkgImage = data;

    self.PYASFcameraView.imageXSize = [[notifData valueForKey:@"xsize"] intValue];
    self.PYASFcameraView.imageYSize = [[notifData valueForKey:@"ysize"] intValue];
    self.PYASFcameraView.imageExists = YES;
    self.PYASFcameraView.turnOnBkgImage = YES;
    
    NSString *logMessage = [NSString stringWithFormat:@"Received image. Size is %ldx%ld = %ld", self.PYASFcameraView.imageXSize, self.PYASFcameraView.imageYSize, (unsigned long)[data length]];
    [self postToLogWindow:logMessage];
    
    [self.PYASFcameraView draw];
}

- (void)postToLogWindow: (NSString *)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:@"message"]];
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
    
    if (self.packet.isSAS1) {
     
        [self.SAS1FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
        [self.SAS1FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
        [self.SAS1CmdCountTextField setIntegerValue:[self.packet commandCount]];
        [self.SAS1CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];
        
        [self.PYASFCameraTemperatureLabel setIntegerValue:self.packet.cameraTemperature];
        if (!NSLocationInRange(self.packet.cameraTemperature, NSMakeRange(10, 20))){
            [self.PYASFCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
        }

        [self.PYASFCTLCmdEchoTextField setStringValue:[NSString stringWithFormat:@"%5.3f, %5.3f", [self.packet.CTLCommand pointValue].x, [self.packet.CTLCommand pointValue].y]];
        [self.PYASFcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
        self.PYASFcameraView.chordCrossingPoints = self.packet.chordPoints;
        self.PYASFcameraView.fiducialPoints = self.packet.fiducialPoints;
        self.PYASFImageMaxMinTextField.stringValue = [NSString stringWithFormat:@"%d, %d", self.packet.ImageRange.location, self.packet.ImageRange.length];
        [self.PYASFcameraView draw];
        NSString *writeString = [NSString stringWithFormat:@"%@, %@, %@, %@, %@\n",
                             self.SAS1FrameTimeLabel.stringValue,
                             self.SAS1FrameNumberLabel.stringValue,
                             self.PYASRCameraTemperatureLabel.stringValue,
                             [NSString stringWithFormat:@"%f, %f", [self.packet.sunCenter pointValue].x,
                                                                    [self.packet.sunCenter pointValue].y],
                             [NSString stringWithFormat:@"%f, %f", [self.packet.CTLCommand pointValue].x,
                                                                    [self.packet.CTLCommand pointValue].y]
                             ];
        [self.SAS1telemetrySaveFile writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if (self.packet.isSAS2) {
        [self.PYASFCameraTemperatureLabel setIntegerValue:self.packet.cameraTemperature];
        [self.PYASRcameraView draw];
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
}

- (IBAction)RunTest:(id)sender {
    
    [self postToLogWindow:@"test string"];
}

@end
