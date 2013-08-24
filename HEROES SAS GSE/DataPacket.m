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

@interface DataPacket()
@property (nonatomic, strong) NSMutableArray *chordPoints;
@property (nonatomic, strong) NSMutableArray *fiducialPoints;
@end

@implementation DataPacket

@synthesize frameNumber = _frameNumber;
@synthesize frameSeconds = _frameSeconds;
@synthesize frameMilliseconds = _frameMilliseconds;
@synthesize commandCount = _commandCount;
@synthesize commandKey = _commandKey;
@synthesize chordPoints = _chordPoints;
@synthesize fiducialPoints = _fiducialPoints;
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
@synthesize isSavingImages;
@synthesize isSunFound;
@synthesize isTracking;
@synthesize aspectErrorCode;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        self.frameMilliseconds = 0;
        self.sunCenter = [NSValue valueWithPoint:NSMakePoint(0.0f, 0.0f)];
        for (int i = 0; i < MAX_CHORDS; i++) {
            [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        }
        for (int i = 0; i < MAX_FIDUCIALS; i++) {
            [self.fiducialPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
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

- (NSMutableArray *)chordPoints
{
    if (_chordPoints == nil) {
        _chordPoints = [[NSMutableArray alloc] init];
    }
    return _chordPoints;
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

- (NSMutableArray *)fiducialPoints
{
    if (_fiducialPoints == nil) {
        _fiducialPoints = [[NSMutableArray alloc] init];
    }
    return _fiducialPoints;
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

- (NSValue *)CTLCommand
{
    if (_CTLCommand == nil) {
        _CTLCommand = [[NSValue alloc] init];
    }
    return _CTLCommand;
}

- (NSString *) getframeTimeString{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.frameSeconds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *zone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:zone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate: date];
    return dateString;
}

- (NSDate *) getDate{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.frameSeconds];
    return date;
}

-(void) addChordPoint:(NSPoint)point :(int) index{
    [self.chordPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
}

-(void) addFiducialPoint:(NSPoint)point :(int) index{
    [self.fiducialPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
}

-(void)setIsSAS1:(BOOL)isSAS1{
    _isSAS1 = isSAS1;
    _isSAS2 = !isSAS1;
}

-(void)setIsSAS2:(BOOL)isSAS2{
    _isSAS2 = isSAS2;
    _isSAS1 = !isSAS2;
}

@end
