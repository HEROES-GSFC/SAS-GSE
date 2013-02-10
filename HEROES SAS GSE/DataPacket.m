//
//  DataPacket.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "DataPacket.h"
#include <time.h>

@implementation DataPacket

@synthesize frameNumber = _frameNumber;
@synthesize frameSeconds = _frameSeconds;
@synthesize frameMilliseconds = _frameMilliseconds;
@synthesize commandCount = _commandCount;
@synthesize commandKey = _commandKey;

-(id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        [self setFrameMilliseconds:0];
    }
    return self;
}

-(void) setFrameNumber:(uint32_t)frameNumber{
    _frameNumber = frameNumber;
    
}

-(void) setFrameSeconds:(uint32_t)frameSeconds{
    _frameSeconds = frameSeconds;
}

-(void) setFrameMilliseconds:(uint32_t) frameMilliseconds{
    _frameMilliseconds = frameMilliseconds;
}

-(void) setCommandKey:(uint16_t)commandKey{
    _commandKey = commandKey;
}

-(void) setCommandCount:(uint16_t)commandCount{
    _commandCount = commandCount;
}

-(NSString *) getframeTimeString{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.frameSeconds];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"D HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate: date];
    
    return dateString;
}


@end
