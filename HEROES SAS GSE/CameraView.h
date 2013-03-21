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
@property (nonatomic, strong) NSData *bkgImage;
@property (nonatomic) BOOL turnOnBkgImage;
@property (nonatomic) long imageXSize;
@property (nonatomic) long imageYSize;
@property (nonatomic) BOOL imageExists;

- (void) CameraViewWillTerminate:(NSNotification *)notification;
- (void) draw;
- (void) setCircleCenter: (float)x :(float)y;
- (void) setScreenCenter: (float)x :(float)y;

@end
