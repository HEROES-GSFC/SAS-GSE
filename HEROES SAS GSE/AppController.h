//
//  AppController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/22/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraView.h"

#import "DataPacket.h"
#import "ConsoleWindowController.h"
#import "CommanderWindowController.h"

@interface AppController : NSObject
- (IBAction)OpenWindow_WindowMenuItemAction:(NSMenuItem *)sender;

@property (weak) IBOutlet NSSegmentedControl *StartStopSegmentedControl;

@property (weak) IBOutlet NSProgressIndicator *RunningIndicator;
@property (weak) IBOutlet NSTextField *FrameNumberLabel;
@property (weak) IBOutlet NSTextField *FrameTimeLabel;
@property (weak) IBOutlet NSTextField *PYASFCPUTemperatureLabel;
@property (weak) IBOutlet NSTextField *PYASRCameraTemperatureLabel;
@property (weak) IBOutlet NSTextField *SAS1CmdCountTextField;
@property (weak) IBOutlet NSTextField *SAS1CmdKeyTextField;
@property (nonatomic, strong) IBOutlet CameraView *PYASRcameraView;
@property (nonatomic, strong) IBOutlet CameraView *PYASFcameraView;
@property (weak) IBOutlet NSButton *drawBkgImage_checkbox;
@property (nonatomic, strong) NSFileHandle *telemetrySaveFile;

@property (nonatomic, readonly) CommanderWindowController *Commander_window;
@property (nonatomic, readonly) ConsoleWindowController *Console_window;
- (IBAction)bkgImageIsClicked:(NSButton *)sender;

- (IBAction)StartStopButtonAction:(NSButton *)sender;
- (IBAction)RunTest:(NSButton *)sender;
- (IBAction)saveImage_ButtonAction:(NSButton *)sender;

@end
