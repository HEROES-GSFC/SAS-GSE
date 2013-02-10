//
//  AppController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/22/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraView.h"
#import "TemperatureFormatter.h"
#import "DataPacket.h"
#import "Commander.h"

@class PreferencesWindowController;
@class CommandingWindowController;
@class TemperatureFormatter;
@class DataPacket;
@class Commander;

@interface AppController : NSObject{
@private
    PreferencesWindowController *preferencesWindowController;
    CommandingWindowController *commandingWindowController;
    TemperatureFormatter *temperatureFormatter;
    Commander *commander;
}
@property (weak) IBOutlet NSSegmentedControl *StartStopSegmentedControl;

@property (weak) IBOutlet NSProgressIndicator *RunningIndicator;
@property (weak) IBOutlet NSTextField *CommandKeyTextField;
@property (weak) IBOutlet NSTextField *CommandValueTextField;
@property (weak) IBOutlet NSTextField *FrameNumberLabel;
@property (weak) IBOutlet NSTextField *FrameTimeLabel;
@property (weak) IBOutlet NSTextField *PYASFCPUTemperatureLabel;
@property (weak) IBOutlet NSTextField *PYASRCameraTemperatureLabel;
@property (weak) IBOutlet NSScrollView *ConsoleScrollView;
@property (unsafe_unretained) IBOutlet NSTextView *ConsoleTextView;
@property (weak) IBOutlet NSTextField *CommandIPTextField;
@property (weak) IBOutlet NSTextField *SAS1CmdCountTextField;
@property (weak) IBOutlet NSTextField *SAS1CmdKeyTextField;

@property (strong) DataPacket *dataPacket;

- (IBAction)StartStopButtonAction:(id)sender;
- (IBAction)RunTest:(id)sender;
- (IBAction)sendCommandButtonAction:(id)sender;

@end
