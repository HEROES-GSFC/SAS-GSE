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

@class PreferencesWindowController;
@class TemperatureFormatter;
@class DataPacket;

@interface AppController : NSObject{
@private
    PreferencesWindowController *preferencesWindowController;
    TemperatureFormatter *temperatureFormatter;
}

@property (weak) IBOutlet NSFormCell *PYASFTemperatureTextField;
@property (weak) IBOutlet NSFormCell *PYASRTemperatureTextField;
@property (weak) IBOutlet NSButton *StartButton;
@property (weak) IBOutlet NSButton *StopButton;
@property (weak) IBOutlet NSProgressIndicator *RunningIndicator;
@property (weak) IBOutlet NSFormCell *FrameNumberTextField;
@property (weak) IBOutlet NSFormCell *FrameTimeTextField;

@property (strong) DataPacket *dataPacket;

- (IBAction)StartButtonAction:(id)sender;
- (IBAction)StopButtonAction:(id)sender;
- (IBAction)RunTest:(id)sender;

- (IBAction)showPreferences:(id)sender;

@end
