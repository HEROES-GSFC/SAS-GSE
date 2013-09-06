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
#import "PlotWindowController.h"
#import "RASCameraViewWindow.h"
#import "AutoFlipSwitch.h"

@interface AppController : NSWindowController

@property (weak) IBOutlet NSTextField *SAS1FrameNumberLabel;
@property (weak) IBOutlet NSTextField *SAS2FrameNumberLabel;
@property (weak) IBOutlet NSTextField *SAS1FrameTimeLabel;
@property (weak) IBOutlet NSTextField *SAS2FrameTimeLabel;
@property (weak) IBOutlet NSTextField *SAS2CPUTemperatureLabel;
@property (weak) IBOutlet NSTextField *SAS1CPUTemperatureLabel;
@property (weak) IBOutlet NSTextField *PYASFCameraTemperatureLabel;
@property (weak) IBOutlet NSTextField *PYASRCameraTemperatureLabel;
@property (weak) IBOutlet NSTextField *RASCameraTemperatureLabel;

@property (weak) IBOutlet NSTextField *SAS1CmdKeyTextField;

@property (weak) IBOutlet NSTextField *SAS2CmdKeyTextField;
@property (nonatomic, strong) IBOutlet CameraView *PYASRcameraView;
@property (nonatomic, strong) IBOutlet CameraView *PYASFcameraView;
@property (weak) IBOutlet NSTextField *PYASFCTLCmdEchoTextField;
@property (weak) IBOutlet NSTextField *PYASRCTLCmdEchoTextField;
@property (weak) IBOutlet NSTextField *PYASFImageMaxTextField;
@property (weak) IBOutlet NSTextField *PYASRImageMaxTextField;
@property (weak) IBOutlet NSTextField *RASImageMaxTextField;

@property (weak) IBOutlet NSTextField *PYASFCTLSigmaTextField;
@property (weak) IBOutlet NSTextField *PYASRCTLSigmaTextField;

@property (weak) IBOutlet NSMenu *TimeProfileMenu;
@property (unsafe_unretained) IBOutlet NSWindow *MainWindow;
@property (weak) IBOutlet AutoFlipSwitch *SAS1AutoFlipSwitch;

@property (weak) IBOutlet AutoFlipSwitch *PYASFAutoFlipSwitch;
@property (weak) IBOutlet AutoFlipSwitch *PYASRAutoFlipSwitch;
@property (weak) IBOutlet AutoFlipSwitch *RASAutoFlipSwitch;
@property (weak) IBOutlet AutoFlipSwitch *SAS2AutoFlipSwitch;

@property (weak) IBOutlet NSTextField *SAS1CPUHeatSinkTemp;
@property (weak) IBOutlet NSTextField *SAS1CanTemp;
@property (weak) IBOutlet NSTextField *SAS1HDDTemp;
@property (weak) IBOutlet NSTextField *SAS1HeaterPlateTemp;
@property (weak) IBOutlet NSTextField *SAS1AirTemp;
@property (weak) IBOutlet NSTextField *SAS1RailTemp;

@property (weak) IBOutlet NSTextField *SAS1V1p05Voltage;
@property (weak) IBOutlet NSTextField *SAS1V2p5Voltage;
@property (weak) IBOutlet NSTextField *SAS1V3p3Voltage;
@property (weak) IBOutlet NSTextField *SAS1V5Votlage;
@property (weak) IBOutlet NSTextField *SAS1V12Voltage;

@property (weak) IBOutlet NSTextField *SAS2CPUHeatSinkTemp;
@property (weak) IBOutlet NSTextField *SAS2CanTemp;
@property (weak) IBOutlet NSTextField *SAS2HDDTemp;
@property (weak) IBOutlet NSTextField *SAS2HeaterPlateTemp;
@property (weak) IBOutlet NSTextField *SAS2AirTemp;
@property (weak) IBOutlet NSTextField *SAS2RailTemp;

@property (weak) IBOutlet NSTextField *SAS2V1p05Voltage;
@property (weak) IBOutlet NSTextField *SAS2V2p5Voltage;
@property (weak) IBOutlet NSTextField *SAS2V3p3Voltage;
@property (weak) IBOutlet NSTextField *SAS2V5Votlage;
@property (weak) IBOutlet NSTextField *SAS2V12Voltage;

@property (weak) IBOutlet NSTextField *PYASRAspectErrorCodeTextField;
@property (weak) IBOutlet NSTextField *PYASFAspectErrorCodeTextField;
@property (weak) IBOutlet NSLevelIndicator *PYASRisTracking_indicator;
@property (weak) IBOutlet NSLevelIndicator *PYASFisTracking_indicator;
@property (weak) IBOutlet NSLevelIndicator *PYASRProvidingCTL_indicator;
@property (weak) IBOutlet NSLevelIndicator *PYASFProvidingCTL_indicator;
@property (weak) IBOutlet NSLevelIndicator *SAS1ClockSync_indicator;
@property (weak) IBOutlet NSLevelIndicator *SAS2ClockSync_indicator;
@property (weak) IBOutlet NSLevelIndicator *SAS2isSavingImages;
@property (weak) IBOutlet NSLevelIndicator *SAS1isSavingImages;
@property (weak) IBOutlet NSTextField *SAS1DroppedFrameTextField;
@property (weak) IBOutlet NSTextField *SAS2DroppedFrameTextField;
@property (weak) IBOutlet NSLevelIndicator *SAS1ReceivingGPS_indicator;
@property (weak) IBOutlet NSLevelIndicator *SAS2ReceivingGPS_indicator;


@property (nonatomic) NSUInteger SAS1MissedFrameCount;
@property (nonatomic) NSUInteger SAS2MissedFrameCount;

@property (nonatomic, strong) RASCameraViewWindow *rasCameraViewWindow;
@property (nonatomic, strong) NSFileHandle *SAS1telemetrySaveFile;
@property (nonatomic, strong) NSFileHandle *SAS2telemetrySaveFile;
@property (nonatomic, strong) NSDictionary *timeSeriesCollection;

@property (nonatomic, readonly) ConsoleWindowController *Console_window;
@property (nonatomic, strong) NSMutableDictionary *PlotWindows;

- (IBAction)RunTest:(NSButton *)sender;
- (IBAction)PYASsaveImage_ButtonAction:(NSButton *)sender;
- (IBAction)OpenWindow_WindowMenuItemAction:(NSMenuItem *)sender;
- (IBAction)ClearPYASBkgImage:(NSButton *)sender;
- (IBAction)SetNewNetworkLocation:(NSPopUpButton *)sender;
- (IBAction)ConsoleSurpressACKToggle:(NSButton *)sender;

- (void)postToLogWindow: (NSString *)message;
- (NSArray *)convertDegreesToDegMinSec: (float)value;

@end
