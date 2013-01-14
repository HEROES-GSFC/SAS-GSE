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
    @private
    int numberXPixels;
    int numberYPixels;
}
// declaration of private methods as needed
- (void) prepareOpenGL;
- (void) drawObjects;
- (void) drawACross: (NSPoint) center;
- (void) drawACircle: (NSPoint) center: (float) radius;
- (void) drawAFewPoints: (NSMutableArray *)points;
- (void) doSomething;
- (void) drawRect: (NSRect) dirtyRect;
- (void) drawALine: (NSPoint) center: (float) length: (float) angleInDegrees;
- (void) cleanUp;
- (NSPoint) calculateCentroid:(NSMutableArray *)points;

@end

@implementation CameraView

@synthesize myNumber = _myNumber;

-(id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        //initialization
        _myNumber = 5;
        numberXPixels = 1392;
        numberYPixels = 1040;
    }
    return self;
}

- (void)awakeFromNib
{
    [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(draw) userInfo:nil repeats:true];
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
    
    gluOrtho2D(0,numberXPixels, 0, numberYPixels);
    glMatrixMode(GL_MODELVIEW);
    
    glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void) drawObjects
{
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:1];
    NSDictionary *circleFitResult = [[NSDictionary alloc] init];
    
    [points addObject:[NSValue valueWithPoint:
                       NSMakePoint(100.0f + numberXPixels/2.0f + 3*(arc4random_uniform(100)/100.0f), numberYPixels/2.0f + 3*(arc4random_uniform(100)/100.0f))]];
    [points addObject:[NSValue valueWithPoint:
                       NSMakePoint(-100.0f + numberXPixels/2.0f + 3*(arc4random_uniform(100)/100.0f), numberYPixels/2.0f + 3*(arc4random_uniform(100)/100.0f))]];
    [points addObject:[NSValue valueWithPoint:
                       NSMakePoint(numberXPixels/2.0f + 3*(arc4random_uniform(100)/100.0f), 100.0f + numberYPixels/2.0f + 3*(arc4random_uniform(100)/100.0f))]];
    [points addObject:[NSValue valueWithPoint:
                       NSMakePoint(numberXPixels/2.0f + 3*(arc4random_uniform(100)/100.0f), -100.0f + numberYPixels/2.0f + 3*(arc4random_uniform(100)/100.0f))]];

    circleFitResult = [self fitCircle:points];
    
    [self drawACross:[[circleFitResult objectForKey:@"centroid"] pointValue]];
    
    [self drawACircle:[[circleFitResult objectForKey:@"centroid"] pointValue]:[[circleFitResult objectForKey:@"radius"] floatValue]];
    glColor3f(0.0f, 1.0f, 0.0f);
    [self drawALine:[[circleFitResult objectForKey:@"centroid"] pointValue] :210.0 :20.0];
    glColor3f(1.0f, 1.0f, 1.0f);
    [self drawAFewPoints:points];
}

- (void) drawACross: (NSPoint) center
{
    float width = 0.02 * (numberXPixels + numberYPixels)/2.0f;
    
    glColor3f(1.0f, 0.0f, 0.0f);
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

- (void) drawACircle: (NSPoint) center: (float) radius
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

-(void) drawALine: (NSPoint) center: (float) length: (float) angleInDegrees
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
    glColor3f(1.0f, 1.0f, 1.0f);
    glBegin(GL_POINTS);
    
    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        glVertex2d(currentPoint.x, currentPoint.y);
    }
    glEnd();
}

- (void) doSomething
{
    //_myNumber+=0.01;
    //if (_myNumber > 10) {
    //    _myNumber = 0;
    // }
    
    
    
    [self drawObjects];
}

- (NSPoint) calculateCentroid:(NSMutableArray *)points
{
    //
    // Calculate the centroid given an array of NSPoints
    //
    NSPoint centroid = NSMakePoint(0.0f, 0.0f);
    
    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        centroid.x += currentPoint.x;
        centroid.y += currentPoint.y;
    }
    centroid.x = centroid.x/[points count];
    centroid.y = centroid.y/[points count];
    
    return centroid;
}

- (float) calculateRadius:(NSMutableArray *)points: (NSPoint) centroid
{
    float radius = 0, ri = 0;
    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        ri = sqrtf(powf(currentPoint.x - centroid.x, 2.0f) + powf(currentPoint.y - centroid.y, 2.0f));
        radius += ri;
    }
    radius = radius / [points count];
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
