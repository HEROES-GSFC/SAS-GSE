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

@interface CameraView()
@property (nonatomic, strong) NSNumber *numberXPixels;
@property (nonatomic, strong) NSNumber *numberYPixels;
@property (nonatomic) float circleX;
@property (nonatomic) float circleY;
@property (nonatomic) float screenX;
@property (nonatomic) float screenY;
@property (nonatomic) float calibratedScreenX;
@property (nonatomic) float calibratedScreenY;

// declaration of private methods as needed
- (void) prepareOpenGL;
- (void) drawACross: (NSPoint) center :(float) widthAsPercentOfScreen;
- (void) drawACircle: (NSPoint) center :(float) radius;
- (void) drawAFewPoints: (NSArray *)points;
- (void) drawAFewCrosses: (NSArray *)centers;
- (void) drawOverlay;
- (void) drawRect: (NSRect) dirtyRect;
- (void) drawImage;
- (void) drawALine: (NSPoint) center :(float) length :(float) angleInDegrees;
- (void) cleanUp;
- (void) mouseDown: (NSEvent *)theEvent;
- (NSPoint) calculateCentroid:(NSMutableArray *)points;
@property (nonatomic) NSPoint mouseLocation;
@end

@implementation CameraView

@synthesize fiducialPoints = _fiducialPoints;
@synthesize chordCrossingPoints = _chordCrossingPoints;
@synthesize northAngle;
@synthesize numberYPixels = _numberYPixels;
@synthesize numberXPixels = _numberXPixels;
@synthesize bkgImage = _bkgImage;
@synthesize turnOnBkgImage = _turnOnBkgImage;
@synthesize imageExists = _imageExists;
@synthesize imageXSize;
@synthesize imageYSize;
@synthesize mouseLocation = _mouseLocation;
@synthesize screenRadius;
@synthesize circleX;
@synthesize circleY;
@synthesize screenX;
@synthesize screenY;
@synthesize clockingAngle;
@synthesize fiducialIDs = _fiducialIDs;
@synthesize calibratedScreenX;
@synthesize calibratedScreenY;

-(id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        //initialization
        self.circleX = 0.0;
        self.circleY = 0.0;
        self.screenX = 500.0;
        self.screenY = 500.0;
        self.calibratedScreenX = 525.0;
        self.calibratedScreenY = 525.0;
        self.turnOnBkgImage = NO;
        self.imageExists = NO;
        self.mouseLocation = NSMakePoint(-1, -1);
    }
    return self;
}

-(void)setTurnOnBkgImage:(BOOL)turnOnBkgImage{
    _turnOnBkgImage = turnOnBkgImage;
    [self needsDisplay];
}

-(NSData *)bkgImage{
    if (_bkgImage == nil) {
        _bkgImage = [[NSData alloc] init];
    }
    return _bkgImage;
}

- (void) setScreenCenter: (float)x :(float)y{
    if ((x < [self.numberXPixels floatValue]) && (x > 0)) {
        self.screenX = x;
    }
    if ((y < [self.numberYPixels floatValue]) && (y > 0)) {
        self.screenY = y;
    }
}

- (void) setCalibratedScreenCenter: (float)x :(float)y{
    if ((x < [self.numberXPixels floatValue]) && (x > 0)) {
        self.calibratedScreenX = x;
    }
    if ((y < [self.numberYPixels floatValue]) && (y > 0)) {
        self.calibratedScreenY = y;
    }
}

-(void)setImageExists:(BOOL)imageExists{
    _imageExists = imageExists;
}

-(BOOL)imageExists{
    return _imageExists;
}


- (NSArray *)fiducialIDs
{
    if (_fiducialIDs == nil) {
        _fiducialIDs = [[NSArray alloc] init];
    }
    return _fiducialIDs;
}

- (NSArray *)fiducialPoints
{
    if (_fiducialPoints == nil) {
        _fiducialPoints = [[NSArray alloc] init];
    }
    return _fiducialPoints;
}

- (NSArray *)chordCrossingPoints
{
    if (_chordCrossingPoints == nil) {
        _chordCrossingPoints = [[NSArray alloc] init];
    }
    return _chordCrossingPoints;
}

- (NSNumber *)numberXPixels
{
    if (_numberXPixels == nil){
        _numberXPixels = [[NSNumber alloc] initWithInt:1296];
    }
    return _numberXPixels;
}

- (NSNumber *)numberYPixels
{
    if (_numberYPixels == nil){
        _numberYPixels = [[NSNumber alloc] initWithInt:966];
    }
    return _numberYPixels;
}

- (void) drawOverlay
{
    NSPoint sunCenter = NSMakePoint(self.circleX, self.circleY);
    NSPoint screenCenter = NSMakePoint(self.screenX, self.screenY);
    NSPoint calibratedScreenCenter = NSMakePoint(self.calibratedScreenX, self.calibratedScreenY);
    
    // draw the Sun (circle and cross)
    glColor3f(1.0f, 0.0f, 0.0f);
    [self drawACross: sunCenter:0.02];
    [self drawACircle: sunCenter: 92];
    
    // draw Sun distances
    glColor3f(0.3f, 0.3f, 0.3f);
    [self drawACircle: sunCenter: 92*2];
    [self drawACircle: sunCenter: 92*3];
    [self drawACircle: sunCenter: 92*4];
    [self drawACircle: sunCenter: 92*5];
    
    
    // draw the screen center
    glColor3f(0.7f, 0.7f, 0.7f);
    [self drawACross:screenCenter :0.015];

    // draw the CALIBRATED screen center
    glColor3f(0.7f, 0.7f, 0.0f);
    [self drawACross:calibratedScreenCenter :0.02];
    
    // draw the screen outline
    glColor3f(0.7f, 0.7f, 0.7f);
    [self drawACircle:screenCenter :self.screenRadius];
    
    // draw solar north angle
    glColor3f(0.0f, 1.0f, 0.0f);
    [self drawALine:sunCenter :213.0 :self.northAngle];
    
    // draw the fiducials
    glColor3f(1.0f, 1.0f, 1.0f);
    [self drawAFewPoints:self.chordCrossingPoints];
    glColor3f(0.0f, 1.0f, 1.0f);
    [self drawAFewCrosses:self.fiducialPoints WithLabels:self.fiducialIDs];
    
    // draw elevation/azimuth coordinates
    glColor3f(0.0f, 1.0f, 1.0f);
    [self drawALine:NSMakePoint(50, 50) :50 :self.clockingAngle];
    [self drawText:NSMakePoint(100, 60) :@"El"];

    glColor3f(1.0f, 1.0f, 1.0f);
    [self drawALine:NSMakePoint(50, 50) :50 :self.clockingAngle + 90];
    [self drawText:NSMakePoint(100, 90) :@"Az"];
    
    // draw mouse location if screen is clicked
    if (self.mouseLocation.x != -1) {
        //NSLog(@"mouse lcoation is %f, %f", self.mouseLocation.x, self.mouseLocation.y);
        [self drawACross:self.mouseLocation :0.02];
        unsigned char pixelValue;
        if (self.imageExists){
            [self.bkgImage getBytes:&pixelValue range:NSMakeRange(self.mouseLocation.x + ((int) self.mouseLocation.y) * self.imageXSize, 1)];
        } else {
            pixelValue = 0;
        }
        NSString *text = [NSString stringWithFormat:@"%u, %f, %f", pixelValue, self.mouseLocation.x, self.mouseLocation.y];
        [self drawText:self.mouseLocation :text];
    }
}

- (void) setCircleCenter: (float)x :(float)y{
    self.circleX = x;
    self.circleY = y;
}

- (void)awakeFromNib
{
    //[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(draw) userInfo:nil repeats:true];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(draw) name:@"ReceiveAndParseDataDidFinish" object:nil];
}

- (void)draw
{
    [self drawOverlay];    
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent {
    //[self setFrameColor:[NSColor redColor]];
    //[self setNeedsDisplay:YES];
    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //mouseLoc = [NSEvent mouseLocation]; //get current mouse position
    self.mouseLocation = NSMakePoint(curPoint.x / [self bounds].size.width * [self.numberXPixels intValue], [self.numberYPixels intValue] - curPoint.y / [self bounds].size.height * [self.numberYPixels intValue]);
    [self setNeedsDisplay:YES];
}

- (void) drawImage{
    GLuint texture;
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    //glOrtho(0.0, glutGet(GLUT_WINDOW_WIDTH), 0.0, glutGet(GLUT_WINDOW_HEIGHT), -1.0, 1.0);
    gluOrtho2D(0, self.numberXPixels.intValue, self.numberYPixels.intValue, 0);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    
    glLoadIdentity();
    glDisable(GL_LIGHTING);
    
    glColor3f(1,1,1);
    glEnable(GL_TEXTURE_2D);
    
    //uint8_t *pixels = (uint8_t *)malloc(self.imageXSize * imageYSize);
    NSUInteger len = [self.bkgImage length];
    Byte *pixels = (Byte *)malloc(len);
    memcpy(pixels, [self.bkgImage bytes], len);
    
    [self.bkgImage getBytes:pixels length:(self.imageXSize*self.imageYSize)];
    
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
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, self.imageXSize, self.imageYSize, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels);
    
    glBindTexture(GL_TEXTURE_2D, texture);
    // Draw a textured quad
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0, 0, 0);
    glTexCoord2f(0, 1); glVertex3f(0, self.numberYPixels.intValue, 0);
    glTexCoord2f(1, 1); glVertex3f(self.numberXPixels.intValue, self.numberYPixels.intValue, 0);
    glTexCoord2f(1, 0); glVertex3f(self.numberXPixels.intValue  , 0, 0);
    glEnd();
    
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    
    glMatrixMode(GL_MODELVIEW);
    free(pixels);
}


-(void) drawRect: (NSRect)dirtyRect
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    if (self.bkgImage != nil && self.imageExists && self.turnOnBkgImage){
        [self drawImage];
    }
    
    [self drawOverlay];
    glFlush();
}

// set initial OpenGL state (current context is set)
// called after context is created
- (void) prepareOpenGL
{
	// init GL stuff here
    glLoadIdentity();
    glPushMatrix();
    
    gluOrtho2D(0,self.numberXPixels.integerValue, 0, self.numberYPixels.integerValue);
    glMatrixMode(GL_MODELVIEW);
    
    glScalef(1, -1, 1);
    glTranslatef(0, -self.numberYPixels.integerValue, 0);

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

-(void) drawText: (NSPoint) origin :(NSString *)text
{
    glRasterPos2f(origin.x, origin.y);
    for (int i = 0; i < [text length]; i++) {
        glutBitmapCharacter(GLUT_BITMAP_TIMES_ROMAN_10, [text characterAtIndex:i]);
    }
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

- (void) drawAFewPoints: (NSArray *)points
{
    glBegin(GL_POINTS);
    
    for (NSValue *value in points){
        NSPoint currentPoint = [value pointValue];
        glVertex2d(currentPoint.x, currentPoint.y);
    }
    glEnd();
}

- (void) drawAFewCrosses: (NSArray *)centers WithLabels: (NSArray *)labels
{
    float currentColor[4];
    glGetFloatv(GL_CURRENT_COLOR,currentColor);
    int i = 0;
    for (NSValue *value in centers){
        NSPoint currentPoint = [value pointValue];
        [self drawACross:currentPoint :0.01];
        if (labels != nil) {
            glColor3f(0.5, 0.5, 0.5);
            NSPoint currentLabel = [[labels objectAtIndex:i] pointValue];
            NSString *label = [NSString stringWithFormat:@"%d%d", (int)currentLabel.x, (int)currentLabel.y];
            [self drawText:NSMakePoint(currentPoint.x-35, currentPoint.y-10) :label];
            glColor3f(currentColor[0], currentColor[1], currentColor[2]);
        }
        i++;
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
    
    //[super clean];
} // cleanUp

@end
