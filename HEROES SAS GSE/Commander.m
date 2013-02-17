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
    NSDictionary *listOfCommands;
    CommandSender *comSender;
}

- (void) printPacket;
- (void) send;

@end

@implementation Commander

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // initialize our subclass here
        serverIP = @"192.168.1.114";
        port = 5001;
        frame_sequence_number = 0;
        
        NSArray *commandKeys = [NSArray arrayWithObjects:
                                [NSNumber numberWithInteger:0x0100],
                                [NSNumber numberWithInteger:0x0101],
                                [NSNumber numberWithInteger:0x0102], nil];
                                
        NSArray *commandDescriptionNSArray = [NSArray
                                              arrayWithObjects:
                                              @"Reset Camera",
                                              @"Set new coordinate",
                                              @"Set blah", nil];
        
        listOfCommands = [NSDictionary
                          dictionaryWithObject:commandDescriptionNSArray
                          forKey:commandKeys];
    }
    return self;
}

-(uint16_t)send:(uint16_t)command_key :(uint16_t)command_value :(NSString *)ip_address{

    // update the frame number every time we send out a packet
    [self updateSequenceNumber];
    
    Command cm1(0x10ff, command_key);
    
    CommandPacket cp(0x30, frame_sequence_number);
    cp << cm1;
    
    comSender = new CommandSender( [ip_address UTF8String], port );
    comSender->send( &cp );
    comSender->close_connection();
    
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
