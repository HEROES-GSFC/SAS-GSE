//
//  AppController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/22/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "AppController.h"
#import "PreferencesWindowController.h"
#import "ParseDataOperation.h"
#import "DataPacket.h"
#import "lib_crc.h"

@interface AppController (){
    NSOperationQueue *queue;
    NSTimer	*timer;
}

@property (retain) NSTimer *timer;

@end

@implementation AppController

// GUI Elements
@synthesize StopButton;
@synthesize StartButton;
@synthesize RunningIndicator;
@synthesize PYASFTemperatureTextField;
@synthesize PYASRTemperatureTextField;
@synthesize FrameNumberTextField;
@synthesize FrameTimeTextField;

@synthesize timer;

@class DataPacket;

- (id)init
{
	self = [super init];
	if (self)
    {
        queue = [[NSOperationQueue alloc] init];
	}
	return self;
}


- (IBAction)StartButtonAction:(id)sender {
    [queue cancelAllOperations];
    
    // start the GetPathsOperation with the root path to start the search
	ParseDataOperation *parseOp = [[ParseDataOperation alloc] init];
	
    [queue addOperation:parseOp];	// this will start the "TestOperation"
    
    if([[queue operations] containsObject:parseOp]){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(anyThread_handleData:)
                                                     name:kReceiveAndParseDataDidFinish
                                                   object:nil];

        [RunningIndicator setHidden:NO];
        [RunningIndicator startAnimation:self];
        [StartButton setEnabled:NO];
        [StopButton setEnabled:YES];
    }
}

- (IBAction)StopButtonAction:(id)sender {
    [queue cancelAllOperations];
    [RunningIndicator setHidden:YES];
    [RunningIndicator stopAnimation:self];
    [StartButton setEnabled:YES];
    [StopButton setEnabled:NO];
}

- (IBAction)RunTest:(id)sender {
    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
    // calculate the checksum
    
    
    [PYASFTemperatureTextField setFloatValue:-100];
}

- (IBAction)showPreferences:(id)sender{
    
    // lazy instantiation, only initialize if window is opened
    if (!preferencesWindowController) {
        preferencesWindowController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];
    }
    [preferencesWindowController showWindow:self];
}

// -------------------------------------------------------------------------------
//	anyThread_handleLoadedImages:note
//
//	This method is called from any possible thread (any NSOperation) used to
//	update our table view and its data source.
//
//	The notification contains the NSDictionary containing the image file's info
//	to add to the table view.
// -------------------------------------------------------------------------------
- (void)anyThread_handleData:(NSNotification *)note
{
	// update our table view on the main thread
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
    
    DataPacket *packet = [notifData valueForKey:@"packet"];
 
    [FrameNumberTextField setIntegerValue:[packet frameNumber]];
 
}


@end
