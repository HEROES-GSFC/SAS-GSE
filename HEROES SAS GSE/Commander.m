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
    uint8_t *payload;
    NSString *serverIP;
    uint16_t syncWord;
    NSDictionary *listOfCommands;
}

- (uint16_t) calculateChecksum;
- (void) addChecksum;
- (void) buildHeader;
- (void) initSocket;
- (void) closeSocket;
- (void) updateSequenceNumber;
- (bool) testChecksum;
- (void) printPacket;
- (void) buildPayload;
- (void) sendPacket;

@end

@implementation Commander

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        // initialize our subclass here
        serverIP = @"192.168.2.221";
        serverPort = 7000;
        payloadLen = 14;
        frame_sequence_number = 0;
        syncWord = 0xc39a;

        payload=(uint8_t *) malloc(payloadLen*sizeof(uint8_t));
        
        NSArray *commandKeys = [NSArray arrayWithObjects:
                                [NSNumber numberWithInteger:0x010],
                                [NSNumber numberWithInteger:0x0101],
                                [NSNumber numberWithInteger:0x0102], nil];
                                
        NSArray *commandDescriptionNSArray = [NSArray
                                              arrayWithObjects:
                                              @"Reset Camera",
                                              @"Set new coordinate",
                                              @"Set blah", nil];
        
        listOfCommands = [NSDictionary dictionaryWithObject:commandDescriptionNSArray forKey:commandKeys];
    }
    return self;
}

- (void) closeSocket{
    close(sock);
}

-(void)send:(uint16_t)command_key :(uint16_t)command_value{

    // update the frame number every time we send out a packet
    [self updateSequenceNumber];
    [self buildHeader];
    [self buildPayload:command_key:command_value];
    [self addChecksum];
    [self printPacket];
    [self sendPacket];
}

-(void)sendPacket{
    
    NSLog(@"Sending to %@\n", serverIP);
    
    /* Create a datagram/UDP socket */
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
        NSLog(@"socket() failed");
    
    /* Construct the server address structure */
    memset(&ServAddr, 0, sizeof(ServAddr));    /* Zero out structure */
    ServAddr.sin_family = AF_INET;                 /* Internet addr family */
    ServAddr.sin_addr.s_addr = inet_addr([serverIP  UTF8String]);  /* Server IP address */
    ServAddr.sin_port   = htons(serverPort);     /* Server port */
    
    /* Send the string to the server */
    if (sendto(sock, payload, payloadLen, 0, (struct sockaddr *)
               &ServAddr, sizeof(ServAddr)) != payloadLen)
        NSLog(@"sendto() sent a different number of bytes than expected");
}

bool testChecksum( void )
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

- (void) updateSequenceNumber{
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
    payload[7] = (uint8_t) (checksum >> 8);
    NSLog(@"checksum is %x", checksum);
}

- (void) buildHeader{
    // build the HEROES Command Packet Header (see Table 6-1)
    // uint16 - the sync word, split into two 8 bit chars
    payload[0] = (uint8_t) syncWord & 0xFF;
    payload[1] = (uint8_t) (syncWord>> 8);
    payload[2] = 0x30;              // destination SAS (Table 6-2)
    payload[3] = payloadLen;      // size of the packet in bytes
    payload[4] = (uint8_t) (frame_sequence_number >> 8);                 // packet sequence number2
    payload[5] = (uint8_t) frame_sequence_number & 0xFF;                 // packet sequence number1
    payload[6] = 0;                 // checksum1
    payload[7] = 0;                 // checksum1
    payload[8] = (uint8_t) 0x10ff & 0xFF;       // RAW command for SAS
    payload[9] = (uint8_t) (0x10ff >> 8); // RAW command for SAS
}

- (void) buildPayload:(uint16_t)command_key:(uint16_t)command_value{
    payload[10] = (uint8_t) (command_key >> 8);
    payload[11] = (uint8_t) command_key & 0xff;
    payload[12] = (uint8_t) (command_value >> 8);
    payload[13] = (uint8_t) command_value & 0xff;
}

- (void) initSocket{
    
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

- (void) printPacket{
    for(int i = 0; i <= payloadLen-1; i++)
    {
        NSLog(@"%i:%x", i, payload[i]);
    }
}

@end
