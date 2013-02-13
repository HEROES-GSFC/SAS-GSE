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

-(NSString *) getframeTimeString;
-(void) setFrameNumber:(uint32_t)frameNumber;
-(void) setFrameSeconds:(uint32_t)frameSeconds;
-(void) setFrameMilliseconds:(uint32_t) frameMilliseconds;
-(void) setcommandKey:(uint16_t)commandKey;
-(void) setcommandCount:(uint16_t)commandCount;


@end
