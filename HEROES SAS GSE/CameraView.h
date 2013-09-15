//
//  CameraView.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 11/9/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CameraView : NSOpenGLView

@property (nonatomic, strong) NSArray *fiducialPoints;
@property (nonatomic, strong) NSArray *chordCrossingPoints;
@property (nonatomic, strong) NSArray *fiducialIDs;
@property (nonatomic) double northAngle;
@property (nonatomic, strong) NSData *bkgImage;
@property (nonatomic) BOOL turnOnBkgImage;
@property (nonatomic) GLsizei imageXSize;
@property (nonatomic) GLsizei imageYSize;
@property (nonatomic) BOOL imageExists;
@property (nonatomic) float screenRadius;
@property (nonatomic) float clockingAngle;

- (void) CameraViewWillTerminate:(NSNotification *)notification;
- (void) draw;
- (void) setCircleCenter: (float)x :(float)y;
- (void) setScreenCenter: (float)x :(float)y;
- (void) setCalibratedScreenCenter: (float)x :(float)y;

@end
