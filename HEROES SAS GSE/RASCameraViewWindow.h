//
//  RASCameraViewWindow.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 5/16/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CameraView.h"

@interface RASCameraViewWindow : NSWindowController

@property (nonatomic, strong) CameraView *cameraView;

@end
