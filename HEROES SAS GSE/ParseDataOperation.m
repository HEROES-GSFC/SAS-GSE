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
#include "time.h"

#import "ParseDataOperation.h"
#import "DataPacket.h"
#import "UDPReceiver.hpp"
#import "Telemetry.hpp"
#import "types.hpp"

#define PAYLOAD_SIZE 20
#define DEFAULT_PORT 5003 /* The default port to send on */

#define SAS_TARGET_ID 0x30
#define SAS_TM_TYPE 0x70
#define SAS_IMAGE_TYPE 0x82
#define SAS1_SYNC_WORD 0xEB90
#define SAS2_SYNC_WORD 0xF626
#define SAS_CM_ACK_TYPE 0x01

#define NUM_LIMBS 8
#define NUM_FIDUCIALS 6

// NSNotification name to tell the Window controller an image file as found
NSString *kReceiveAndParseDataDidFinish = @"ReceiveAndParseDataDidFinish";

@interface ParseDataOperation(){
    UDPReceiver *tmReceiver;
}

@property (nonatomic, strong) DataPacket *dataPacket;
- (void)postToLogWindow: (NSString *)message;
@end

@implementation ParseDataOperation

@synthesize dataPacket = _dataPacket;

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        tmReceiver = new TelemetryReceiver( 5002 );
    }
    return self;
}

- (DataPacket *)dataPacket
{
    if (_dataPacket == nil) {
        _dataPacket = [[DataPacket alloc] init];
    }
    return _dataPacket;
}

- (void)postToLogWindow: (NSString *)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:@"message"]];
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    @autoreleasepool {

        tmReceiver->init_connection();

        while (1) {
            
            if ([self isCancelled])
            {
                break;	// user cancelled this operation
            }
            
            uint16_t packet_length = tmReceiver->listen();
            if( packet_length != 0){
                uint8_t *packet;
                packet = new uint8_t[packet_length];
                tmReceiver->get_packet( packet );
            
                TelemetryPacket *tm_packet;
                tm_packet = new TelemetryPacket( packet, packet_length);
                
                if (tm_packet->valid())
                {
                    if (tm_packet->getSourceID() == SAS_TARGET_ID){
                        if (tm_packet->getTypeID() == SAS_TM_TYPE) {
                            
                            if (tm_packet->getSync() == SAS1_SYNC_WORD) {
                                self.dataPacket.isSAS1=TRUE;
                            }
                            if (tm_packet->getSync() == SAS2_SYNC_WORD) {
                                self.dataPacket.isSAS2=TRUE;
                            }
                            
                            [self.dataPacket setFrameSeconds: tm_packet->getSeconds()];
                            
                            uint16_t sas_sync;
                            *(tm_packet) >> sas_sync;
                            //NSLog(@"%x", sas_sync);
                            uint32_t frame_number;
                            *(tm_packet) >> frame_number;
                            uint16_t command_count;
                            *(tm_packet) >> command_count;
                            uint16_t command_key;
                            *(tm_packet) >> command_key;

                            uint16_t housekeeping1, housekeeping2;
                            *(tm_packet) >> housekeeping1 >> housekeeping2;

                            //For now, housekeeping1 is always camera temperature
                            self.dataPacket.cameraTemperature = (int)housekeeping1;

                            Pair3B sunCenter, sunCenterError;
                            *(tm_packet) >> sunCenter >> sunCenterError;

                            [self.dataPacket setSunCenter:[NSValue valueWithPoint:NSMakePoint(sunCenter.x(), sunCenter.y())]];

                            Pair3B predictCenter, predictCenterError;
                            *(tm_packet) >> predictCenter >> predictCenterError;

                            uint16_t nLimbs;
                            *(tm_packet) >> nLimbs;

                            for (int i = 0; i < NUM_LIMBS; i++) {
                                Pair3B limb;
                                *(tm_packet) >> limb;
                                [self.dataPacket addChordPoint:NSMakePoint(limb.x(),limb.y()) :i];
                            }

                            uint16_t nFiducials;
                            *(tm_packet) >> nFiducials;

                            for (int i = 0; i < NUM_FIDUCIALS; i++) {
                                Pair3B fiducial;
                                *(tm_packet) >> fiducial;
                                [self.dataPacket addFiducialPoint:NSMakePoint(fiducial.x(),fiducial.y()) :i];
                            }

                            float x_intercept, x_slope;
                            *(tm_packet) >> x_intercept >> x_slope;

                            float y_intercept, y_slope;
                            *(tm_packet) >> y_intercept >> y_slope;

                            uint8_t image_max, image_min;
                            *(tm_packet) >> image_max >> image_min;

                            [self.dataPacket setFrameNumber: frame_number];
                            [self.dataPacket setCommandCount: command_count];
                            [self.dataPacket setCommandKey: command_key];
                            
                            double ctl_xvalue, ctl_yvalue;
                            *(tm_packet) >> ctl_xvalue >> ctl_yvalue;
                            [self.dataPacket setCTLCommand:[NSValue valueWithPoint:NSMakePoint(ctl_xvalue, ctl_yvalue)]];
                        }
                        
                        if (tm_packet->getTypeID() == SAS_CM_ACK_TYPE) {
                            uint16_t sequence_number = 0;
                            *tm_packet >> sequence_number;
                            
                            NSString *msg = [NSString stringWithFormat:@"Received ACK for %u", sequence_number];
                            [self postToLogWindow:msg];
                        }
                    }
                    
                }
                
                free(packet);
                free(tm_packet);
            }

                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      self.dataPacket, @"packet",
                                      nil];
                if (![self isCancelled])
//              {
                    // for the purposes of this sample, we're just going to post the information
                    // out there and let whoever might be interested receive it (in our case its MyWindowController).
                    [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseDataDidFinish object:nil userInfo:info];
                }
//}
            //[self setQueuePriority:2.0];      // second priority
    }
}



@end
