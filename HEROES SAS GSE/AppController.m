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

@synthesize timer;
@synthesize dataPacket;

- (id)init
{
	self = [super init];
	if (self)
    {
        queue = [[NSOperationQueue alloc] init];
        dataPacket = [[DataPacket alloc] init];
	}
	return self;
}


- (IBAction)StartButtonAction:(id)sender {
    [queue cancelAllOperations];
    
    // start the GetPathsOperation with the root path to start the search
	ParseDataOperation *parseOp = [[ParseDataOperation alloc] init];
	
	[queue addOperation:parseOp];	// this will start the "TestOperation"
    
    // schedule our update timer for our UI
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(RunningIndicator:)
                                                userInfo:nil
                                                 repeats:YES];
    
    
    [StartButton setEnabled:NO];
    [StopButton setEnabled:YES];
}

- (IBAction)StopButtonAction:(id)sender {
    [queue cancelAllOperations];
    [StartButton setEnabled:YES];
    [StopButton setEnabled:NO];
}

- (IBAction)RunTest:(id)sender {
    [dataPacket setFrameNumber:3];
    //[PYASFTemperatureTextField setFloatValue:-100];
}

- (IBAction)showPreferences:(id)sender{
    
    // lazy instantiation, only initialize if window is opened
    if (!preferencesWindowController) {
        preferencesWindowController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];
    }
    [preferencesWindowController showWindow:self];
}

@end
