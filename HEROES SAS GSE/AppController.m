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
@end

@implementation AppController

// GUI Elements
@synthesize RunningIndicator;
@synthesize PYASFCPUTemperatureLabel;
@synthesize PYASRCameraTemperatureLabel;
@synthesize FrameNumberLabel;
@synthesize FrameTimeLabel;
@synthesize StartStopSegmentedControl;
@synthesize SAS1CmdCountTextField;
@synthesize SAS1CmdKeyTextField;
@synthesize PYASFcameraView = _PYASFcameraView;
@synthesize PYASRcameraView = _PYASRcameraView;
@synthesize Commander_window = _Commander_window;
@synthesize Console_window = _Console_window;

@synthesize timer = _timer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize packet = _packet;

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
            NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
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
                                                     selector:@selector(anyThread_handleData:)
                                                         name:kReceiveAndParseDataDidFinish
                                                       object:nil];
            
        }
    }
    if ([StartStopSegmentedControl selectedSegment] == 1) {
        [self.queue cancelAllOperations];
        [self.RunningIndicator setHidden:YES];
        [self.RunningIndicator stopAnimation:self];
    }

}

- (IBAction)saveImage_ButtonAction:(NSButton *)sender {
    
    unsigned char buffer[100];
    for (int j = 0; j < 100; j++) {
        buffer[j] = j;
    }
    
    NSData *imagedata = [NSData dataWithBytes:buffer length:sizeof(buffer)];
    
    NSBitmapImageRep *greyRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:10 pixelsHigh:10 bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:0 bitsPerPixel:8];
    
    NSInteger rowBytes = [greyRep bytesPerRow];
    unsigned char *pix = [greyRep bitmapData];
    
    //memcpy(pix, buffer, 100);
    
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            pix[i * rowBytes + j] = (unsigned char)(255 * buffer[i * 10 + j]);
        }
    }
    
    NSImage *greyscale = [[NSImage alloc] initWithSize:NSMakeSize(10, 10)];
    [greyscale addRepresentation:greyRep];
    
    NSData *temp = [greyscale TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:temp];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imagedata = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    
    NSSavePanel* panel = [NSSavePanel savePanel];
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel setNameFieldStringValue:@"boo.png"];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *theFile = [panel URL];
            [imagedata writeToFile:[theFile path] atomically:YES];
        }
    }];

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

- (void)anyThread_handleImage:(NSNotification *)image
{
    [self performSelectorOnMainThread:@selector(mainThread_handleImage:) withObject:image waitUntilDone:NO];
}

- (void)mainThread_handleImage:(NSNotification *)image
{
    NSLog(@"got it");
}

// -------------------------------------------------------------------------------
//	mainThread_handleLoadedImages:note
//
//	The method used to modify the table's data source on the main thread.
//	This will cause the table to update itself once the NSArrayController is changed.
//
//	The notification contains an NSDictionary containing the image file's info
//	to add to the table view.
// -------------------------------------------------------------------------------
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
 
    [self.FrameNumberLabel setIntegerValue:[self.packet frameNumber]];
    [self.FrameTimeLabel setStringValue:[self.packet getframeTimeString]];
    [self.SAS1CmdCountTextField setIntegerValue:[self.packet commandCount]];
    [self.SAS1CmdKeyTextField setStringValue:[NSString stringWithFormat:@"0x%04x", [self.packet commandKey]]];
    
    NSRange tempRange = NSMakeRange(10, 20);
    [self.PYASRCameraTemperatureLabel setIntegerValue:self.packet.cameraTemperature];
    if (NSLocationInRange(self.packet.cameraTemperature, tempRange) == FALSE){
        [self.PYASRCameraTemperatureLabel setBackgroundColor:[NSColor redColor]];
    }

    [self.PYASFcameraView setCircleCenter:[self.packet.sunCenter pointValue].x :[self.packet.sunCenter pointValue].y];
    self.PYASFcameraView.chordCrossingPoints = self.packet.chordPoints;
    self.PYASFcameraView.fiducialPoints = self.packet.fiducialPoints;
    [self.PYASFcameraView draw];
    [self.PYASRcameraView draw];
    
    
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
    
    //for (int i = 0; i < 100; i++) {
    //    [self.ConsoleTextView insertText:@"hello"];
    //}
    //[self.ConsoleScrollView insertText:[NSString stringWithFormat:@"hidden? = %i", [self.CommanderHelperWindow isHidden]]];
    //NSLog(@"hidden? = %b", [self.CommanderHelperWindow isHidden]);
    //[self.CommanderHelperWindow setHidden:YES];
    [self.Console_window log:@"hello"];
}

@end
