//
//  DataPacket.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataPacket : NSObject

@property (nonatomic) uint8_t frameNumber;
@property (nonatomic) uint32_t frameSeconds;
@property (nonatomic) uint32_t frameMilliseconds;

-(NSString *) getframeTimeString;

@end
