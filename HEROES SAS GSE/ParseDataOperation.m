//
//  ParseDataOperation.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/28/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//
// Reference:
// http://www.raywenderlich.com/19788/how-to-use-nsoperations-and-nsoperationqueues

#include <sys/socket.h> /* for socket() and bind() */
#include <arpa/inet.h>  /* for sockaddr_in and inet_ntoa() */
#include <string.h>     /* for memset() */
#include <unistd.h>     /* for close() */
#include "lib_crc.h"

#import "ParseDataOperation.h"
#import "DataPacket.h"

#define PAYLOAD_SIZE 9
#define DEFAULT_PORT 7000 /* The default port to send on */

// NSNotification name to tell the Window controller an image file as found
NSString *kReceiveAndParseDataDidFinish = @"ReceiveAndParseDataDidFinish";

@interface ParseDataOperation(){
    DataPacket *dataPacket;
}
    
@property (retain) DataPacket *dataPacket;

@end

@implementation ParseDataOperation

@synthesize dataPacket;

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    @autoreleasepool {
        
        int sock;                        /* Socket */
        struct sockaddr_in echoServAddr; /* Local address */
        struct sockaddr_in echoClntAddr; /* Client address */
        unsigned int cliAddrLen;         /* Length of incoming message */
        char payload[PAYLOAD_SIZE];      /* payload to send to server */
        unsigned short echoServPort;     /* Server port */
        int recvMsgSize;                 /* Size of received message */

        DataPacket* dataPacket = [[DataPacket alloc] init];
        
        echoServPort = DEFAULT_PORT;
        
        /* Create socket for sending/receiving datagrams */
        if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0){
            NSLog(@"socket() failed");
        }
        
        /* Construct local address structure */
        memset(&echoServAddr, 0, sizeof(echoServAddr));   /* Zero out structure */
        echoServAddr.sin_family = AF_INET;                /* Internet address family */
        echoServAddr.sin_addr.s_addr = htonl(INADDR_ANY); /* Any incoming interface */
        echoServAddr.sin_port = htons(echoServPort);      /* Local port */
        
        /* Bind to the local address */
        if (bind(sock, (struct sockaddr *) &echoServAddr, sizeof(echoServAddr)) < 0)
            NSLog(@"bind() failed");
        
        while (1) {
            
            if ([self isCancelled])
            {
                break;	// user cancelled this operation
            }
            
            //sleep(1);
            NSLog(@"Listening...");
            
             /* Set the size of the in-out parameter */
            cliAddrLen = sizeof(echoClntAddr);
            
            /* Block until receive message from a client */
            if ((recvMsgSize = recvfrom(sock, payload, sizeof(payload), 0,
                                        (struct sockaddr *) &echoClntAddr, &cliAddrLen)) < 0){
                NSLog(@"recvfrom() failed");
            } else {
                NSLog(@"Receiving Packet.");
                NSLog(@"Handling client %s\n", inet_ntoa(echoClntAddr.sin_addr));

                // initialize checksum
                unsigned short crc_16_modbus_checksum  = 0xffff;
                
                for(int i = 0; i < sizeof(payload)-1; i++){
                    NSLog(@"Received message %u\n", (uint8_t) payload[i]);
                    crc_16_modbus_checksum  = update_crc_16( crc_16_modbus_checksum, payload[i]);
                }

                uint16_t sync;
                sync = (((uint16_t) payload[1] << 8) & 0xFF00) + ((uint8_t) payload[0]);
                NSLog(@"payload[0] %u\n", (uint8_t) payload[0]);
                
                NSLog(@"sync word is %u\n", sync);
                
                [dataPacket setFrameNumber:payload[5]];
                NSLog(@"frame number is %u\n", (uint8_t) [dataPacket frameNumber]);

                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      dataPacket, @"packet",
                                      nil];
                
                NSLog(@"checksum is %x", crc_16_modbus_checksum);
                if (![self isCancelled])
                {
                    // for the purposes of this sample, we're just going to post the information
                    // out there and let whoever might be interested receive it (in our case its MyWindowController).
                    //
                    [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseDataDidFinish object:nil userInfo:info];
                }
            }
            //[self setQueuePriority:2.0];      // second priority
        }
    }
}



@end
