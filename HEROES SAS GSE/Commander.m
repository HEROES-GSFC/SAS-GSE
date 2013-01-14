//
//  Commanding.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 1/13/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "Commander.h"
#include <sys/socket.h> /* for socket(), connect(), sendto(), and recvfrom() */
#include <arpa/inet.h>  /* for sockaddr_in and inet_addr() */
#include "lib_crc.h"

#define DEFAULT_PORT 7001 /* The default port to send on */
#define PAYLOAD_SIZE 9     /* Longest string to echo */

@interface Commander(){
@private
    int sock;                       // Socket descriptor
    struct sockaddr_in ServAddr;    // Echo server address
    struct sockaddr_in fromAddr;    // Source address of echo
    unsigned short serverPort;        // Echo server port
    unsigned int fromSize;          // In-out of address size for recvfrom()
    size_t payloadLen;              // Length of payload
    int recvMsgSize;                // Size of received message
    struct sockaddr_in ClntAddr; /* Client address */
    unsigned int cliAddrLen;         /* Length of incoming message */
    uint16_t frame_sequence_number;
    uint8_t payload[10];
    NSString *serverIP;
}

- (uint16_t) calculateChecksum;
- (void) addChecksum;
- (void) buildHeader;
- (void) initSocket;
- (void) update_sequence_number;
- (bool) test_checksum;
- (void) buildPayload;

@end

@implementation Commander

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // initialize our subclass here
        serverIP = @"10.1.49.140";
        serverPort = 7000;
        frame_sequence_number = 0;
    }
    return self;
}

-(void)send:(uint16_t)command_key :(uint16_t)command_value{

    // update the frame number every time we send out a packet
    [self update_sequence_number];
    [self buildHeader];
    [self buildPayload:command_key:command_value];
    [self addChecksum];
    
    NSLog(@"Sending to %@\n", serverIP);
    
    /* Create a datagram/UDP socket */
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
        NSLog(@"socket() failed");
    
    /* Construct the server address structure */
    memset(&ServAddr, 0, sizeof(ServAddr));    /* Zero out structure */
    ServAddr.sin_family = AF_INET;                 /* Internet addr family */
    ServAddr.sin_addr.s_addr = inet_addr([serverIP  cString]);  /* Server IP address */
    ServAddr.sin_port   = htons(serverPort);     /* Server port */
    
    /* Send the string to the server */
    if (sendto(sock, payload, payloadLen, 0, (struct sockaddr *)
               &ServAddr, sizeof(ServAddr)) != payloadLen)
        NSLog(@"sendto() sent a different number of bytes than expected");
}

bool test_checksum( void )
{
    // initialize check sum variable
    unsigned short checksum;
    checksum = 0xffff;
    
    char test[] = "123456789";
    for(int i = 0; i < sizeof(test)-1; i++){
        checksum = update_crc_16( checksum, (char) test[i] );}
    NSLog(@"4b37 vs calculated %x\n", checksum);
    if (checksum == 0x4b37) return 1; else return 0;
}

- (void) update_sequence_number{
    frame_sequence_number++;
}

- (uint16_t) calculateChecksum{
    // initialize check sum variable
    unsigned short checksum;
    checksum = 0xffff;
    
    // calculate the checksum but leave out the last value as it contains the checksum
    for(int i = 0; i < sizeof(payload)-2; i++){
        checksum = update_crc_16( checksum, payload[i] );}

    return checksum;
}

-(void) addChecksum{
    uint16_t checksum = [self calculateChecksum];
    
    payload[6] = (uint8_t) checksum  & 0xFF;
    payload[7] = (uint8_t) checksum & 0xFF00 >> 8;
    NSLog(@"checksum is %x", checksum);
}

- (void) buildHeader{
    // build the HEROES Command Packet Header (see Table 6-1)
    // uint16 - the sync word, split into two 8 bit chars
    payload[0] = (uint8_t) 0xc39a & 0xFF;
    payload[1] = (uint8_t) (0xc39a & 0xFF00) >> 8;
    payload[2] = 0x30;              // destination SAS (Table 6-2)
    payload[3] = PAYLOAD_SIZE;      // size of the packet in bytes
    payload[4] = frame_sequence_number & 0xFF;                 // packet sequence number1
    payload[5] = frame_sequence_number & 0xFF00 >> 8;                 // packet sequence number2
    payload[6] = 0;                 // checksum1
    payload[7] = 0;                 // checksum1
    payload[8] = (uint8_t) 0x10ff & 0xFF;       // RAW command for SAS
    payload[9] = (uint8_t) (0x10ff & 0xFF00) >> 8; // RAW command for SAS
}

- (void) buildPayload:(uint16_t)command_key:(uint16_t)command_value{
    payload[10] = (uint8_t) command_key & 0xFF;
    payload[11] = (uint8_t) (command_key & 0xFF00) >> 8;
    payload[12] = (uint8_t) command_value & 0xFF;
    payload[13] = (uint8_t) (command_value & 0xFF00) >> 8;
}

- (void) initSocket{
    serverPort = DEFAULT_PORT;
    
    /* Create socket for sending/receiving datagrams */
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
        NSLog(@"socket() failed");
    
    /* Construct local address structure */
    memset(&ServAddr, 0, sizeof(ServAddr));   /* Zero out structure */
    ServAddr.sin_family = AF_INET;                /* Internet address family */
    ServAddr.sin_addr.s_addr = htonl(INADDR_ANY); /* Any incoming interface */
    ServAddr.sin_port = htons(serverPort);      /* Local port */
    
    /* Bind to the local address */
    if (bind(sock, (struct sockaddr *) &ServAddr, sizeof(ServAddr)) < 0)
        NSLog(@"bind() failed");
}

@end
