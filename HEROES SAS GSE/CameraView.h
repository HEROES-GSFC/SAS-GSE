//
//  CameraView.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 11/9/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CameraView : NSOpenGLView

@property (nonatomic) NSValue *circleCenter;

- (void) CameraViewWillTerminate:(NSNotification *)notification;
- (void) draw;
- (void) setCircleCenter:(NSValue *)center;

@end
