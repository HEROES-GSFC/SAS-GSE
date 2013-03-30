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
@property (weak) IBOutlet NSTextField *SAS1FrameNumberLabel;
@property (weak) IBOutlet NSTextField *SAS2FrameNumberLabel;
@property (weak) IBOutlet NSTextField *SAS1FrameTimeLabel;
@property (weak) IBOutlet NSTextField *SAS2FrameTimeLabel;
@property (weak) IBOutlet NSTextField *SAS2CPUTemperatureLabel;
@property (weak) IBOutlet NSTextField *SAS1CPUTemperatureLabel;
@property (weak) IBOutlet NSTextField *PYASFCameraTemperatureLabel;
@property (weak) IBOutlet NSTextField *PYASRCameraTemperatureLabel;
@property (weak) IBOutlet NSTextField *RASCameraTemperatureLabel;
@property (weak) IBOutlet NSTextField *SAS1CmdCountTextField;
@property (weak) IBOutlet NSTextField *SAS1CmdKeyTextField;
@property (weak) IBOutlet NSTextField *SAS2CmdCountTextField;
@property (weak) IBOutlet NSTextField *SAS2CmdKeyTextField;
@property (nonatomic, strong) IBOutlet CameraView *PYASRcameraView;
@property (nonatomic, strong) IBOutlet CameraView *PYASFcameraView;
@property (weak) IBOutlet NSButton *PYASFdrawBkgImage_checkbox;
@property (weak) IBOutlet NSTextField *PYASFCTLCmdEchoTextField;
@property (weak) IBOutlet NSTextField *PYASRCTLCmdEchoTextField;

@property (nonatomic, strong) NSFileHandle *SAS1telemetrySaveFile;
@property (nonatomic, strong) NSFileHandle *SAS2telemetrySaveFile;

@property (nonatomic, readonly) CommanderWindowController *Commander_window;
@property (nonatomic, readonly) ConsoleWindowController *Console_window;
- (IBAction)bkgImageIsClicked:(NSButton *)sender;

- (IBAction)StartStopButtonAction:(NSButton *)sender;
- (IBAction)RunTest:(NSButton *)sender;
- (IBAction)saveImage_ButtonAction:(NSButton *)sender;
- (void)postToLogWindow: (NSString *)message;

@end
