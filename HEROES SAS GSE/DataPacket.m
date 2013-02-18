//
//  DataPacket.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "DataPacket.h"
#include <time.h>
@interface DataPacket()
@property (nonatomic, strong) NSMutableArray *chordPoints;
@end

@implementation DataPacket

@synthesize frameNumber = _frameNumber;
@synthesize frameSeconds = _frameSeconds;
@synthesize frameMilliseconds = _frameMilliseconds;
@synthesize commandCount = _commandCount;
@synthesize commandKey = _commandKey;
@synthesize chordPoints = _chordPoints;
@synthesize sunCenter = _sunCenter;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        self.frameMilliseconds = 0;
        self.sunCenter = [NSValue valueWithPoint:NSMakePoint(0.0f, 0.0f)];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
        [self.chordPoints addObject:[NSValue valueWithPoint:NSMakePoint(0,0)]];
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

- (NSValue *)sunCenter
{
    if (_sunCenter == nil) {
        _sunCenter = [[NSValue alloc] init];
    }
    return _sunCenter;
}

- (NSString *) getframeTimeString{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.frameSeconds];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"D HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate: date];
    
    return dateString;
}

-(void) addChordPoint:(NSPoint)point :(int) index{
    [self.chordPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
}

@end
