//
//  DataPacket.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataPacket : NSObject

@property (nonatomic) uint32_t frameNumber;
@property (nonatomic) uint32_t frameSeconds;
@property (nonatomic) uint32_t frameMilliseconds;
@property (nonatomic) uint16_t commandCount;
@property (nonatomic) uint16_t commandKey;
@property (nonatomic) NSValue *sunCenter;
@property (nonatomic) NSValue *CTLCommand;
@property (nonatomic) int cameraTemperature;
@property (nonatomic) int cpuTemperature;
@property (nonatomic) BOOL isSAS1;
@property (nonatomic) BOOL isSAS2;

-(NSString *) getframeTimeString;
-(void) addChordPoint: (NSPoint) point :(int) index;
-(void) addFiducialPoint: (NSPoint) point :(int) index;
-(NSMutableArray *) chordPoints;
-(NSMutableArray *) fiducialPoints;

@end
