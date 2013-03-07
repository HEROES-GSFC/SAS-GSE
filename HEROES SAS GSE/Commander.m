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

@interface Commander(){
@private
    uint16_t frame_sequence_number;
    NSString *serverIP;
    unsigned int port;
    CommandSender *comSender;
}

- (void) printPacket;

@end

@implementation Commander

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // initialize our subclass here
        serverIP = @"192.168.1.114";
        port = 5001;
        frame_sequence_number = 0;
        
    }
    return self;
}

-(uint16_t)send :(uint16_t)command_key :(NSMutableArray *)command_variables :(NSString *)ip_address{

    comSender = new CommandSender( [ip_address UTF8String], port );
    CommandPacket cp(0x30, frame_sequence_number);
    Command cm(0x10ff, command_key);
    if (!command_variables) {
        try{
        cp << cm; //should be this but does not seem to work
        } catch (std::exception& e) {
            std::cerr << e.what() << std::endl;
        }
        } else {
        for (NSNumber *variable in command_variables) {
            cp << (uint16_t)[variable intValue];
        }
    }
    
    comSender->send( &cp );
    comSender->close_connection();

    // update the frame number every time we send out a packet
    [self updateSequenceNumber];
    
    return frame_sequence_number;
}

- (void) updateSequenceNumber{
    frame_sequence_number++;
}


- (void) printPacket{
    //for(int i = 0; i <= payloadLen-1; i++)
    //{
    //    NSLog(@"%i:%x", i, payload[i]);
    //}
}

@end
