//
//  Commanding.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 1/13/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "Commander.h"
#include "lib_crc.h"
#include "Command.hpp"
#include "UDPSender.hpp"

#define GROUND_NETWORK true /* Change this as appropriate */

#if GROUND_NETWORK
#define SAS_CMD_PORT 2001 /* The command port on the ground network */
#else
#define SAS_CMD_PORT 2000 /* The command port on the flight network */
#endif

@interface Commander()
@property (nonatomic) uint16_t frame_sequence_number;
@end

@implementation Commander

@synthesize frame_sequence_number;

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // initialize our subclass here
        self.frame_sequence_number = 0;
    }
    return self;
}

-(uint16_t)send :(uint16_t)command_key :(NSArray *)command_variables :(NSString *)ip_address{
    CommandSender comSender = CommandSender( [ip_address UTF8String], SAS_CMD_PORT );
    CommandPacket cp(0x30, self.frame_sequence_number);
    Command cm(0x10ff, command_key);
    if (command_variables != nil) {
        for (NSNumber *variable in command_variables) {
            cm << (uint16_t)[variable intValue];
        }
    }
    try{
        cp << cm;
    } catch (std::exception& e) {
        std::cerr << e.what() << std::endl;
    }

    comSender.send( &cp );
    comSender.close_connection();

    // update the frame number every time we send out a packet
    self.frame_sequence_number++;
    return self.frame_sequence_number;
}

@end
