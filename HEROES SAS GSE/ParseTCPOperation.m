//
//  ParseTCPOperation.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/24/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//
#import "ParseTCPOperation.h"

#import "DataPacket.h"
#import "TCPReceiver.hpp"
#import "Telemetry.hpp"

#define PAYLOAD_SIZE 
#define DEFAULT_PORT 5010 /* The default port to send on */

#define SAS_TARGET_ID 0x30
#define SAS_TM_TYPE 0x70
#define SAS_IMAGE_TYPE 0x82
#define SAS_SYNC_WORD 0xEB90
#define SAS_CM_ACK_TYPE 0x01

// NSNotification name to tell the Window controller an image file as found
NSString *kReceiveAndParseImageDidFinish = @"ReceiveAndParseImageDidFinish";


@interface ParseTCPOperation(){
    TCPReceiver *tcpReceiver;
}
@property (nonatomic, retain) NSImage *image;

@end

@implementation ParseTCPOperation

@synthesize image = _image;

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        tcpReceiver = new TCPReceiver( 5010 );
    }
    return self;
}

- (NSImage *)image{
    if (_image == nil) {
        _image = [[NSImage alloc] init];
    }
    return _image;
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    @autoreleasepool {
        
        tcpReceiver->init_connection();
        
        while (1) {
            
            if ([self isCancelled])
            {
                break;	// user cancelled this operation
            }
            int sock = tcpReceiver->accept_packet();
            NSLog(@"client connected!");
            while(sock > 0){
                int packet_length;
                packet_length = tcpReceiver->handle_tcpclient(sock);
                NSLog(@"got it %i", packet_length);
                if( packet_length > 0){
                    uint8_t *packet;
                    packet = new uint8_t[packet_length];
                    tcpReceiver->get_packet( packet );
                
                    TelemetryPacket *tm_packet;
                    tm_packet = new TelemetryPacket( packet, packet_length);
                
                    if (tm_packet->valid())
                    {
                        if (tm_packet->getSourceID() == SAS_TARGET_ID){
                            
                            if (tm_packet->getTypeID() == SAS_TM_TYPE) {
                                                            //for(int i = 0; i < packet_length-1; i++){
                                //    printf("%x", (uint8_t) packet[i]);
                                //}
                                //printf("\n");
                            }
                            
                        }
                    
                    } else {NSLog(@"not tm packet");}
                
                free(packet);
                free(tm_packet);
                }
            }
            
            //NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
            //                      self.image, @"image", nil];
            if (![self isCancelled]){}
                //    [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseImageDidFinish object:nil userInfo:info];
                
        }
    }
}

@end

