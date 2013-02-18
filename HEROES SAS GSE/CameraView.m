//
//  CameraView.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 11/9/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "CameraView.h"
#include <OpenGL/gl.h>
#import <GLUT/GLUT.h>
#include <math.h>
#include <stdlib.h>

@interface CameraView(){
    float circleX;
    float circleY;
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
- (void) drawALine: (NSPoint) center :(float) length :(float) angleInDegrees;
- (void) cleanUp;
- (NSPoint) calculateCentroid:(NSMutableArray *)points;
@end

@implementation CameraView

@synthesize fiducialPoints = _fiducialPoints;
@synthesize chordCrossingPoints = _chordCrossingPoints;
@synthesize numberYPixels = _numberYPixels;
@synthesize numberXPixels = _numberXPixels;


-(id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        //initialization
        circleX = 0.0;
        circleY = 0.0;
    }
    return self;
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
    
    glColor3f(1.0f, 0.0f, 0.0f);
    [self drawACross:sunCenter:0.02];
    [self drawACircle: sunCenter: 92];
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
	glEnable(GL_DEPTH_TEST);
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
