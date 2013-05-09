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
#import "PlotWindowController.h"

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
@property (weak) IBOutlet NSTextField *SAS1CmdCountTextField;
@property (weak) IBOutlet NSTextField *SAS1CmdKeyTextField;
@property (weak) IBOutlet NSTextField *SAS2CmdCountTextField;
@property (weak) IBOutlet NSTextField *SAS2CmdKeyTextField;
@property (nonatomic, strong) IBOutlet CameraView *PYASRcameraView;
@property (nonatomic, strong) IBOutlet CameraView *PYASFcameraView;
@property (weak) IBOutlet NSButton *PYASFdrawBkgImage_checkbox;
@property (weak) IBOutlet NSButton *PYASRdrawBkgImage_checkbox;
@property (weak) IBOutlet NSTextField *PYASFCTLCmdEchoTextField;
@property (weak) IBOutlet NSTextField *PYASRCTLCmdEchoTextField;
@property (weak) IBOutlet NSTextField *PYASFImageMaxMinTextField;
@property (weak) IBOutlet NSTextField *PYASRImageMaxMinTextField;
@property (weak) IBOutlet NSTextField *PYASFCTLSigmaTextField;
@property (weak) IBOutlet NSForm *PYASFTemperaturesForm;
@property (weak) IBOutlet NSForm *PYASRTemperaturesForm;

@property (nonatomic, strong) NSFileHandle *SAS1telemetrySaveFile;
@property (nonatomic, strong) NSFileHandle *SAS2telemetrySaveFile;
@property (weak) IBOutlet NSMenu *TimeProfileMenu;

@property (nonatomic, strong) NSDictionary *timeSeriesCollection;
@property (nonatomic, strong) NSDictionary *PYASFtimeSeriesCollection;
@property (nonatomic, strong) NSDictionary *PYASRtimeSeriesCollection;
@property (nonatomic, strong) NSDictionary *RAStimeSeriesCollection;

@property (nonatomic, readonly) CommanderWindowController *Commander_window;
@property (nonatomic, readonly) ConsoleWindowController *Console_window;
@property (nonatomic, strong) NSMutableDictionary *PlotWindows;
@property (unsafe_unretained) IBOutlet NSWindow *MainWindow;

- (IBAction)PYASRbkgImageIsClicked:(NSButton *)sender;
- (IBAction)PYASFbkgImageIsClicked:(NSButton *)sender;
- (IBAction)RunTest:(NSButton *)sender;
- (IBAction)PYASFsaveImage_ButtonAction:(NSButton *)sender;
- (IBAction)PYASRsaveImage_ButtonAction:(NSButton *)sender;
- (void)postToLogWindow: (NSString *)message;
- (IBAction)OpenWindow_WindowMenuItemAction:(NSMenuItem *)sender;

@end
