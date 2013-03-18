//
//  CameraView.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 11/9/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "CameraView.h"
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#import <GLUT/GLUT.h>
#include <math.h>
#include <stdlib.h>

@interface CameraView(){
    float circleX;
    float circleY;
    float screenX;
    float screenY;
}
@property (nonatomic, strong) NSNumber *numberXPixels;
@property (nonatomic, strong) NSNumber *numberYPixels;

// declaration of private methods as needed
- (void) prepareOpenGL;
- (void) drawACross: (NSPoint) center :(float) widthAsPercentOfScreen;
- (void) drawACircle: (NSPoint) center :(float) radius;
- (void) drawAFewPoints: (NSMutableArray *)points;
- (void) drawAFewCrosses: (NSMutableArray *)centers;
- (void) doSomething;
- (void) drawRect: (NSRect) dirtyRect;
- (void) drawImage;
- (void) drawALine: (NSPoint) center :(float) length :(float) angleInDegrees;
- (void) cleanUp;
- (NSPoint) calculateCentroid:(NSMutableArray *)points;
@end

@implementation CameraView

@synthesize fiducialPoints = _fiducialPoints;
@synthesize chordCrossingPoints = _chordCrossingPoints;
@synthesize numberYPixels = _numberYPixels;
@synthesize numberXPixels = _numberXPixels;
@synthesize bkgImage = _bkgImage;
@synthesize turnOnBkgImage = _turnOnBkgImage;

-(id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        //initialization
        circleX = 0.0;
        circleY = 0.0;
        screenX = 500.0;
        screenY = 500.0;
        self.turnOnBkgImage = YES;
    }
    return self;
}

-(void)setTurnOnBkgImage:(BOOL)turnOnBkgImage{
    _turnOnBkgImage = turnOnBkgImage;
    [self needsDisplay];
}

- (void) setBkgImage:(NSMutableArray *)bkgImage{
    bkgImage = _bkgImage;
}

- (NSMutableArray *)bkgImage
{
    if (_bkgImage == nil) {
        _bkgImage = [[NSMutableArray alloc] init];
    }
    return _bkgImage;
}

- (void) setScreenCenter: (float)x :(float)y{
    if ((x < [self.numberXPixels floatValue]) && (x > 0)) {
        screenX = x;
    }
    if ((y > [self.numberYPixels floatValue]) && (y > 0)) {
        screenY = y;
    }
}

- (void) drawImage{
    GLuint texture;
    unsigned char data[] = { 255,0,0, 0,255,0, 0,0,255, 255,255,255 };

    const int size = [self.numberXPixels intValue] * [self.numberYPixels intValue];
    float *pixels = (float *)malloc(size * sizeof(float));
    for(long i = 0; i < size; i++) {
        pixels[i] = i;
    }
    
    glGenTextures( 1, &texture );
    glBindTexture( GL_TEXTURE_2D, texture );
    glPixelStorei( GL_UNPACK_ALIGNMENT, 1 );
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
    //even better quality, but this will do for now.
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    
    //to the edge of our shape.
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    //Generate the texture
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 2, 2, 0,GL_RGB, GL_UNSIGNED_BYTE, data);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    
    glPushMatrix();
    const int iw = [self.numberXPixels intValue];
    const int ih = [self.numberXPixels intValue];
    glTranslatef( -iw/2.0, -ih/2.0, 0 );
    glBegin(GL_QUADS);
    glTexCoord2i(0,0); glVertex2i(0, 0);
    glTexCoord2i(1,0); glVertex2i(iw, 0);
    glTexCoord2i(1,1); glVertex2i(iw, ih);
    glTexCoord2i(0,1); glVertex2i(0, ih);
    glEnd();
    glPopMatrix();
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //for (int i = 0; i < [self.numberXPixels floatValue]; i++) {
    //    for (int j = 0; j < [self.numberYPixels floatValue]; j++) {
    //        if (self.turnOnBkgImage == true) {
    //            grey = (float) i*j / ([self.numberYPixels floatValue] * [self.numberXPixels floatValue]);
    //        } else { grey = 0.0; }
    //        glColor3f(grey, grey, grey);
    //        glVertex2f(i, j); glVertex2f(i+1, j);
    //        glVertex2f(i+1, j+1); glVertex2f(i, j+1);
    //        glEnd();
    //    }
   // }
}

- (NSMutableArray *)fiducialPoints
{
    if (_fiducialPoints == nil) {
        _fiducialPoints = [[NSMutableArray alloc] init];
    }
    return _fiducialPoints;
}

- (NSMutableArray *)chordCrossingPoints
{
    if (_chordCrossingPoints == nil) {
        _chordCrossingPoints = [[NSMutableArray alloc] init];
    }
    return _chordCrossingPoints;
}

- (NSNumber *)numberXPixels
{
    if (_numberXPixels == nil){
        _numberXPixels = [[NSNumber alloc] initWithInt:1392];
    }
    return _numberXPixels;
}

- (NSNumber *)numberYPixels
{
    if (_numberYPixels == nil){
        _numberYPixels = [[NSNumber alloc] initWithInt:1040];
    }
    return _numberYPixels;
}

- (void) doSomething
{
    NSPoint sunCenter = NSMakePoint(circleX, circleY);
    NSPoint screenCenter = NSMakePoint(screenX, screenY);
    
    [self drawImage];
    
    glColor3f(1.0f, 0.0f, 0.0f);
    [self drawACross: sunCenter:0.02];
    [self drawACircle: sunCenter: 92];
    
    glColor3f(0.7f, 0.7f, 0.7f);
    [self drawACross:screenCenter :1.00];
    
    glColor3f(0.0f, 1.0f, 0.0f);
    [self drawALine:sunCenter :213.0 :20.0];
    
    // fit the chord crossing to the chord crossing and show that
    //NSDictionary *circleFitResult = [[NSDictionary alloc] init];
    //circleFitResult = [self fitCircle:self.chordCrossingPoints];
    //[self drawACross:[[circleFitResult objectForKey:@"centroid"] pointValue]];
    //[self drawACircle:[[circleFitResult objectForKey:@"centroid"] pointValue]:[[circleFitResult objectForKey:@"radius"] floatValue]];
    
    glColor3f(1.0f, 1.0f, 1.0f);
    [self drawAFewPoints:self.chordCrossingPoints];
    glColor3f(0.0f, 1.0f, 1.0f);
    [self drawAFewCrosses:self.fiducialPoints];
}

- (void) setCircleCenter: (float)x :(float)y{
    circleX = x;
    circleY = y;
}

- (void)awakeFromNib
{
    //[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(draw) userInfo:nil repeats:true];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(draw) name:@"ReceiveAndParseDataDidFinish" object:nil];
}

- (void)draw
{
    [self doSomething];
    gluLookAt (0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
    glutSwapBuffers();
    [self setNeedsDisplay:YES];
}

-(void) drawRect: (NSRect)dirtyRect
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self doSomething];
    
    glFlush();
    
    //[[self openGLContext] flushBuffer];
}

// set initial OpenGL state (current context is set)
// called after context is created
- (void) prepareOpenGL
{
    //GLint swapInt = 1;
    
    //    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync
    
	// init GL stuff here
    glLoadIdentity();
    glPushMatrix();
    
    gluOrtho2D(0,self.numberXPixels.integerValue, 0, self.numberYPixels.integerValue);
    glMatrixMode(GL_MODELVIEW);
    
    glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void) drawACross: (NSPoint) center :(float) widthAsPercentOfScreen
{
    float width = widthAsPercentOfScreen * (self.numberXPixels.integerValue + self.numberYPixels.integerValue)/2.0f;
    
    glBegin(GL_LINES);
    {
        glVertex2d(center.x - width, center.y);
        glVertex2d(center.x + width, center.y);
    }
    glBegin(GL_LINES);
    {
        glVertex2d(center.x, center.y - width);
        glVertex2d(center.x, center.y + width);
    }
    glEnd();
}

- (void) drawACircle: (NSPoint) center :(float) radius
{
    //
    // algorithm from http://slabode.exofire.net/circle_draw.shtml
    //
    float num_segments = 50.0f;
	float theta = 2 * M_PI / num_segments;

	float c = cosf(theta);//precalculate the sine and cosine
	float s = sinf(theta);
	float t;
    
	float x = radius;//we start at angle = 0
	float y = 0;
    
	glBegin(GL_LINE_LOOP);
	for(int ii = 0; ii < num_segments; ii++)
	{
		glVertex2f(x + center.x, y + center.y); //output vertex
        
		//apply the rotation matrix
		t = x;
		x = c * x - s * y;
		y = s * t + c * y;
	}
	glEnd();
}

-(void) drawALine: (NSPoint) center :(float) length :(float) angleInDegrees
{
    glBegin(GL_LINES);
    {
        glVertex2d(center.x, center.y);
        glVertex2d(center.x + length * sinf(angleInDegrees * M_PI/180.0), center.y + length * cosf(angleInDegrees * M_PI/180.0));
    }
    glEnd();
}

- (void) drawAFewPoints: (NSMutableArray *)points
{
    glBegin(GL_POINTS);
    
    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        glVertex2d(currentPoint.x, currentPoint.y);
    }
    glEnd();
}

- (void) drawAFewCrosses: (NSMutableArray *)centers{    
    for (NSValue *value in centers){
        NSPoint currentPoint = [value pointValue];
        [self drawACross:currentPoint :0.01];
    }
    glEnd();
}

- (NSPoint) calculateCentroid:(NSMutableArray *)points
{
    //
    // Calculate the centroid given an array of NSPoints
    //
    NSPoint centroid = NSMakePoint(0.0f, 0.0f);
    int number_of_zeros = 0;
    
    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        if (currentPoint.x != 0 && currentPoint.y != 0) {
            centroid.x += currentPoint.x;
            centroid.y += currentPoint.y;
        } else { number_of_zeros++; }
    }
    centroid.x = centroid.x/([points count] - number_of_zeros);
    centroid.y = centroid.y/([points count] - number_of_zeros);
    
    return centroid;
}

- (float) calculateRadius:(NSMutableArray *)points :(NSPoint) centroid
{
    float radius = 0.0f, ri = 0.0f;
    int number_of_zeros = 0;

    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        if (currentPoint.x != 0 && currentPoint.y != 0) {
            ri = sqrtf(powf(currentPoint.x - centroid.x, 2.0f) + powf(currentPoint.y - centroid.y, 2.0f));
            radius += ri;
        } else { number_of_zeros++; }
    }
    radius = radius / ([points count] - number_of_zeros);
    return radius;
}

- (NSDictionary *) fitCircle:(NSMutableArray *)points
{
    //
    // Given a number of points, find the best fit circle
    //
    
    NSPoint centroid = [self calculateCentroid:points];
    float radius = [self calculateRadius:points :centroid];

    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSValue valueWithPoint:centroid], @"centroid",
                            [NSNumber numberWithFloat:radius], @"radius", nil];
    
    return result;
}

- (void) CameraViewWillTerminate:(NSNotification *)notification
{
	[self cleanUp];
}

- (void) cleanUp
{
	// Default image pathname
	
	//if( pathname )
	//{
	//	[pathname release];
	//} // if
    
	// Core Image denoise filter
	
//if( denoise )
//{
//		[denoise release];
//	} // if
    
    //[super cleanUp];
} // cleanUp

@end
