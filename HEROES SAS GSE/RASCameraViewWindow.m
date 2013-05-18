//
//  RASCameraViewWindow.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 5/16/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "RASCameraViewWindow.h"

@interface RASCameraViewWindow ()

@end

@implementation RASCameraViewWindow

@synthesize cameraView = _cameraView;

- (CameraView *)cameraView
{
    if (_cameraView == nil) {
        _cameraView = [[CameraView alloc] init];
    }
    return _cameraView;
}

- (id)init{
    return [super initWithWindowNibName:@"RASCameraViewWindow"];
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.cameraView draw];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
