//
//  AppController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/22/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "AppController.h"
#import "ParseDataOperation.h"
#import "DataPacket.h"
#import "lib_crc.h"
#import "CameraView.h"

@interface AppController ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDictionary *listOfCommands;
@property (nonatomic, strong) Commander *commander;
@property (nonatomic, strong) DataPacket *packet;
@end

@implementation AppController

// GUI Elements
@synthesize RunningIndicator;
@synthesize PYASFCPUTemperatureLabel;
@synthesize PYASRCameraTemperatureLabel;
@synthesize FrameNumberLabel;
@synthesize FrameTimeLabel;
@synthesize CommandKeyTextField;
@synthesize CommandValueTextField;
@synthesize StartStopSegmentedControl;
@synthesize ConsoleScrollView;
@synthesize ConsoleTextView;
@synthesize CommandIPTextField;
@synthesize SAS1CmdCountTextField;
@synthesize SAS1CmdKeyTextField;
@synthesize CommandSequenceNumber;
@synthesize PYASFcameraView = _PYASFcameraView;
@synthesize PYASRcameraView = _PYASRcameraView;

@synthesize timer = _timer;
@synthesize listOfCommands = _listOfCommands;
@synthesize queue = _queue;
@synthesize commander = _commander;
@synthesize packet = _packet;

- (id)init
{
	self = [super init];
	if (self)
    {
                
        NSArray *commandKeys = [NSArray arrayWithObjects:
                                [NSNumber numberWithInteger:0x0100],
                                [NSNumber numberWithInteger:0x0101],
                                [NSNumber numberWithInteger:0x0102], nil];
        
        NSArray *commandDescriptionNSArray = [NSArray
                                              arrayWithObjects:
                                              @"Reset Camera",
                                              @"Set new coordinate",
                                              @"Set blah", nil];
        
        self.listOfCommands = [NSDictionary
                          dictionaryWithObject:commandDescriptionNSArray
                          forKey:commandKeys];
        
	}
	return self;
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

- (Commander *)commander
{
    if (_commander == nil) {
        _commander = [[Commander alloc] init];
    }
    return _commander;
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
        
        [self.queue addOperation:parseOp];	// this will start the "TestOperation"
        
        if([[self.queue operations] containsObject:parseOp]){
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(anyThread_handleData:)
                                                         name:kReceiveAndParseDataDidFinish
                                                       object:nil];

            [self.RunningIndicator setHidden:NO];
            [self.RunningIndicator startAnimation:self];
        }
    }
    if ([StartStopSegmentedControl selectedSegment] == 1) {
        [self.queue cancelAllOperations];
        [self.RunningIndicator setHidden:YES];
        [self.RunningIndicator stopAnimation:self];
    }

}

- (IBAction)RunTest:(id)sender {
    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
    // calculate the checksum
    [self.PYASFCPUTemperatureLabel setFloatValue:10.0f];
    [self.PYASFCPUTemperatureLabel setBackgroundColor:[NSColor redColor]];
    for (int i = 0; i < 100; i++) {
        [self.ConsoleTextView insertText:@"hello"];
    }
    
}

//- (IBAction)showPreferencesWindow:(id)sender{
//    
//    // lazy instantiation, only initialize if window is opened
//    if (!preferencesWindowController) {
//        preferencesWindowController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];
//    }
//    [preferencesWindowController showWindow:self];
//}

//- (IBAction)showCommandingWindow:(id)sender{
//    
//    // lazy instantiation, only initialize if window is opened
//    if (!commandingWindowController) {
//        commandingWindowController = [[CommandingWindowController alloc] initWithWindowNibName:@"CommandingWindow"];
//    }
//    [commandingWindowController showWindow:self];
//}

- (IBAction)sendCommandButtonAction:(id)sender{
    uint16_t command_sequence_number = 0;
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:[CommandKeyTextField stringValue]];
    unsigned int command_key;
    if (![scanner scanHexInt:&command_key]) {
        NSLog(@"Invalid hex string");
    }

    NSScanner *scanner2 = [[NSScanner alloc] initWithString:[CommandKeyTextField stringValue]];
    unsigned int command_var;
    if (![scanner2 scanHexInt:&command_var]) {
        NSLog(@"Invalid hex string");
    }

    command_sequence_number = [self.commander send:command_key :command_var: [CommandIPTextField stringValue]];

    [CommandSequenceNumber setIntegerValue:command_sequence_number];
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
    //[self.PYASRcameraView draw];
    
    
}


@end
