//
//  DataPacket.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "DataPacket.h"
#include <time.h>

#define MAX_CHORDS 20
#define MAX_FIDUCIALS 20
#define NUM_I2C_SENSORS 8
#define NUM_VOLTAGE_READINGS 5

//Calibrated parameters
#define CLOCKING_ANGLE_PYASF -32.425 //model is -33.26
#define CENTER_X_PYASF    124.68 //mils
#define CENTER_Y_PYASF    -74.64 //mils
#define TWIST_PYASF 180.0 //needs to be ~180
#define CLOCKING_ANGLE_PYASR -52.175 //model is -53.26
#define CENTER_X_PYASR -105.59 //mils
#define CENTER_Y_PYASR   -48.64 //mils
#define TWIST_PYASR 0.0 //needs to be ~0

@interface DataPacket()
@property (nonatomic, strong) NSMutableArray *chordPoints;
@property (nonatomic, strong) NSMutableArray *fiducialPoints;
@property (nonatomic, strong) NSMutableArray *fiducialIDs;
@end

@implementation DataPacket

@synthesize frameNumber = _frameNumber;
@synthesize frameSeconds = _frameSeconds;
@synthesize frameMilliseconds = _frameMilliseconds;
@synthesize commandCount = _commandCount;
@synthesize commandKey = _commandKey;
@synthesize chordPoints = _chordPoints;
@synthesize fiducialPoints = _fiducialPoints;
@synthesize fiducialIDs = _fiducialIDs;
@synthesize sunCenter = _sunCenter;
@synthesize screenCenter = _screenCenter;
@synthesize CTLCommand = _CTLCommand;
@synthesize cameraTemperature = _cameraTemperature;
@synthesize cpuTemperature = _cpuTemperature;
@synthesize isSAS1 = _isSAS1;
@synthesize isSAS2 = _isSAS2;
@synthesize ImageMax;
@synthesize screenRadius;
@synthesize i2cTemperatures = _i2cTemperatures;
@synthesize isClockSynced;
@synthesize isOutputting;
@synthesize isPYASSavingImages;
@synthesize isRASSavingImages;
@synthesize isReceivingGPS;
@synthesize isTracking;
@synthesize aspectErrorCode;
@synthesize clockingAngle;
@synthesize screenCenterOffset;
@synthesize calibratedScreenCenter = _calibratedScreenCenter;
@synthesize calibratedScreenCenterOffset = _calibratedScreenCenterOffset;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        self.frameMilliseconds = 0;
        self.fiducialPoints = [[NSMutableArray alloc] init];
        self.fiducialIDs = [[NSMutableArray alloc] init];
        self.chordPoints = [[NSMutableArray alloc] init];
        
        self.sunCenter = [NSValue valueWithPoint:NSMakePoint(0.0f, 0.0f)];
        for (int i = 0; i < MAX_CHORDS; i++) {
            [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        }
        for (int i = 0; i < MAX_FIDUCIALS; i++) {
            [self.fiducialPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        }
        for (int i = 0; i < MAX_FIDUCIALS; i++) {
            [self.fiducialIDs addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        }
        for (int i = 0; i < NUM_I2C_SENSORS; i++) {
            [self.i2cTemperatures addObject:[NSNumber numberWithInt:-1]];
        }
        for (int i = 0; i < NUM_VOLTAGE_READINGS; i++) {
            [self.sbcVoltages addObject:[NSNumber numberWithInt:-1]];
        }
    }
    return self;
}

- (NSArray *)getChordPoints
{
    return [self.chordPoints copy];
}

- (NSMutableArray *) i2cTemperatures
{
    if (_i2cTemperatures == nil) {
        _i2cTemperatures = [[NSMutableArray alloc] initWithCapacity:NUM_I2C_SENSORS];
    }
    return _i2cTemperatures;
}

- (NSMutableArray *) sbcVoltages
{
    if (_sbcVoltages == nil) {
        _sbcVoltages = [[NSMutableArray alloc] initWithCapacity:NUM_VOLTAGE_READINGS];
    }
    return _sbcVoltages;
}

- (NSArray *)getFiducialPoints
{
    return [self.fiducialPoints copy];
}

- (NSArray *)getFiducialIDs
{
    return [self.fiducialIDs copy];
}

- (NSValue *)sunCenter
{
    if (_sunCenter == nil) {
        _sunCenter = [[NSValue alloc] init];
    }
    return _sunCenter;
}

- (NSValue *)screenCenter
{
    if (_screenCenter == nil) {
        _screenCenter = [[NSValue alloc] init];
    }
    return _screenCenter;
}

- (NSValue *)calibratedScreenCenter
{
    if (_calibratedScreenCenter == nil) {
        _calibratedScreenCenter = [[NSValue alloc] init];
    }
    return _calibratedScreenCenter;
}

- (NSValue *)calibratedScreenCenterOffset
{
    if (_calibratedScreenCenterOffset == nil) {
        _calibratedScreenCenterOffset = [[NSValue alloc] init];
    }
    return _calibratedScreenCenterOffset;
}


- (NSValue *)CTLCommand
{
    if (_CTLCommand == nil) {
        _CTLCommand = [[NSValue alloc] init];
    }
    return _CTLCommand;
}

- (NSString *) getframeTimeString{
    NSDate *date = [self getDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *zone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:zone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *dateString = [dateFormatter stringFromDate: date];
    return dateString;
}

- (NSDate *) getDate{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(self.frameSeconds + (double)self.frameMilliseconds/1e3)];
    return date;
}

-(void) addChordPoint:(NSPoint)point :(int) index{
    [self.chordPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
}

-(void) addFiducialPoint:(NSPoint)point :(int) index{
    [self.fiducialPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
}

-(void) addFiducialID:(NSPoint)ID :(int) index{
    [self.fiducialIDs replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:ID]];
}

-(void)setIsSAS1:(BOOL)isSAS1{
    _isSAS1 = isSAS1;
    _isSAS2 = !isSAS1;
    if (isSAS1) {
        self.clockingAngle = CLOCKING_ANGLE_PYASF+TWIST_PYASF+180;
        self.calibratedScreenCenterOffset = [NSValue valueWithPoint:NSMakePoint(CENTER_X_PYASF, CENTER_Y_PYASF)];
    } else {
        self.clockingAngle = CLOCKING_ANGLE_PYASR+TWIST_PYASR+180;
        self.calibratedScreenCenterOffset = [NSValue valueWithPoint:NSMakePoint(CENTER_X_PYASR, CENTER_Y_PYASR)];
    }
}

-(void)setIsSAS2:(BOOL)isSAS2{
    _isSAS2 = isSAS2;
    _isSAS1 = !isSAS2;
    [self setIsSAS1:!isSAS2];
}

@end
