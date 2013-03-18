//
//  CameraView.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 11/9/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CameraView : NSOpenGLView

@property (nonatomic, strong) NSMutableArray *fiducialPoints;
@property (nonatomic, strong) NSMutableArray *chordCrossingPoints;
@property (nonatomic, strong) NSMutableArray *bkgImage;
@property (nonatomic) BOOL turnOnBkgImage;

- (void) CameraViewWillTerminate:(NSNotification *)notification;
- (void) draw;
- (void) setCircleCenter: (float)x :(float)y;
- (void) setScreenCenter: (float)x :(float)y;

@end
