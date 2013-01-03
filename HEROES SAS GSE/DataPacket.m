//
//  DataPacket.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "DataPacket.h"

@implementation DataPacket

@synthesize frameNumber = _frameNumber;
@synthesize frameTime = _frameTime;

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
                         // initialize our subclass here
    }
    return self;
}

-(void) setFrameNumber:(uint8_t)frameNumber{
    _frameNumber = frameNumber;
}

-(void) setFrameTime:(uint8_t)frameTime{
    _frameTime = frameTime;
}

@end
