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
#import "AspectError.hpp"

#define PAYLOAD_SIZE 20

#define GROUND_NETWORK true /* Change this as appropriate */

#if GROUND_NETWORK
#define DEFAULT_PORT 2003 /* The telemetry port on the ground network */
#else
#define DEFAULT_PORT 2002 /* The telemetry port on the flight network */
#endif

#define SAS_TARGET_ID 0x30
#define SAS_TM_TYPE 0x70
#define SAS_IMAGE_TYPE 0x82
#define SAS1_SYNC_WORD 0xEB90
#define SAS2_SYNC_WORD 0xF626
#define SAS_CM_ACK_TYPE 0x01
#define SAS_CM_PROC_ACK_TYPE 0xE1

#define NUM_LIMBS 8
#define NUM_FIDUCIALS 6

// NSNotification name to tell the Window controller an image file as found
NSString *kReceiveAndParseDataDidFinish = @"ReceiveAndParseDataDidFinish";

@interface ParseDataOperation()
@property (nonatomic, strong) NSFileHandle *saveFile;
- (void)postToLogWindow: (NSString *)message :(NSString *)name;
@property int port;
@end

@implementation ParseDataOperation

@synthesize saveFile;

- (id)initWithPort: (int)port{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        self.port = port;
        self.saveFile = [[NSFileHandle alloc] init];
    }
    return self;
}

- (void)postToLogWindow: (NSString *)message :(NSString *)name{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:@"message"]];
}

- (void)OpenSaveFile{
    // Create a time string for the filename
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"YYYYMMdd_HHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"HEROES_SAS_tmlog_%@.dat", dateString];
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    self.saveFile = [NSFileHandle fileHandleForWritingAtPath: filePath ];
    if (self.saveFile == nil) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        self.saveFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    [self.saveFile truncateFileAtOffset:[self.saveFile seekToEndOfFile]];
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    TelemetryReceiver tmReceiver = TelemetryReceiver( self.port );
    @autoreleasepool {
        tmReceiver.init_connection();
        [self OpenSaveFile];
        
        while (1) {
            if ([self isCancelled])
            {
                tmReceiver.close_connection();
                [self.saveFile closeFile];
                NSLog(@"Stopping UDP listener and parser");
                break;	// user cancelled this operation
            }
            
            uint16_t packet_length = tmReceiver.listen();
            if( packet_length != 0){
                DataPacket *dataPacket = [[DataPacket alloc] init];

                uint8_t *packet = new uint8_t[packet_length];
                tmReceiver.get_packet( packet );
                
                //save to file
                [self.saveFile writeData:[NSData dataWithBytes:packet length:packet_length]];
                
                TelemetryPacket tm_packet = TelemetryPacket( packet, packet_length );
                
                if (tm_packet.valid())
                {
                    if (tm_packet.getSourceID() == SAS_TARGET_ID){
                        if (tm_packet.getTypeID() == SAS_TM_TYPE) {
                            
                            switch (tm_packet.getSAS()) {
                                case 1:
                                    dataPacket.isSAS1 = TRUE;
                                    break;
                                case 2:
                                    dataPacket.isSAS2 = TRUE;
                                    break;
                                default:
                                    dataPacket.isSAS1 = TRUE;
                                    break;
                            }
                            
                            [dataPacket setFrameSeconds: tm_packet.getSeconds()];
                            
                            uint32_t frame_number;
                            tm_packet >> frame_number;
                            uint8_t status_bitfield;
                            tm_packet >> status_bitfield;
                            
                            [dataPacket setFrameNumber: frame_number];
                            
                            //parse this bit field
                            dataPacket.isTracking = (bool)bitread(&status_bitfield, 7, 1);
                            dataPacket.isSunFound = (bool)bitread(&status_bitfield, 6, 1);
                            dataPacket.isOutputting = (bool)bitread(&status_bitfield, 5, 1);
                            AspectCode result = (AspectCode)bitread(&status_bitfield, 0, 5);
                            dataPacket.aspectErrorCode = [NSString stringWithCString:GetMessage(result) encoding:NSUTF8StringEncoding];
                            
                            dataPacket.frameMilliseconds = tm_packet.getNanoseconds() / 1e6;
                            
                            uint16_t command_key;
                            tm_packet >> command_key;
                            [dataPacket setCommandKey: command_key];
                            
                            uint16_t housekeeping1, housekeeping2;
                            tm_packet >> housekeeping1 >> housekeeping2;
                            
                            switch (frame_number % 8) {
                                case 0:
                                    dataPacket.cpuTemperature = Float2B(housekeeping1).value()/10.;
                                    dataPacket.cameraTemperature = Float2B(housekeeping2).value()/10.;
                                    break;
                                case 1:
                                    [dataPacket.i2cTemperatures replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:Float2B(housekeeping1).value()/10.]];
                                    dataPacket.cameraTemperature = Float2B(housekeeping2).value()/10.;
                                    break;
                                case 2:
                                    [dataPacket.i2cTemperatures replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:Float2B(housekeeping1).value()/10.]];
                                    [dataPacket.sbcVoltages replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:Float2B(housekeeping2).value()/500.0]];
                                    break;
                                case 3:
                                    [dataPacket.i2cTemperatures replaceObjectAtIndex:2 withObject:[NSNumber numberWithFloat:Float2B(housekeeping1).value()/10.]];
                                    [dataPacket.sbcVoltages replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:Float2B(housekeeping2).value()/500.0]];
                                    break;
                                case 4:
                                    [dataPacket.i2cTemperatures replaceObjectAtIndex:3 withObject:[NSNumber numberWithFloat:Float2B(housekeeping1).value()/10.]];
                                    [dataPacket.sbcVoltages replaceObjectAtIndex:2 withObject:[NSNumber numberWithFloat:Float2B(housekeeping2).value()/500.0]];
                                    break;
                                case 5:
                                    [dataPacket.i2cTemperatures replaceObjectAtIndex:4 withObject:[NSNumber numberWithFloat:Float2B(housekeeping1).value()/10.]];
                                    [dataPacket.sbcVoltages replaceObjectAtIndex:3 withObject:[NSNumber numberWithFloat:Float2B(housekeeping2).value()/500.0]];
                                    break;
                                case 6:
                                    [dataPacket.i2cTemperatures replaceObjectAtIndex:5 withObject:[NSNumber numberWithFloat:Float2B(housekeeping1).value()/10.]];
                                    [dataPacket.sbcVoltages replaceObjectAtIndex:4 withObject:[NSNumber numberWithFloat:Float2B(housekeeping2).value()/500.0]];
                                    break;
                                case 7:
                                    dataPacket.isClockSynced = housekeeping1;
                                    dataPacket.isSavingImages = housekeeping2;
                                default:
                                    break;
                            }
                            
                            Pair3B sunCenter, sunCenterError;
                            tm_packet >> sunCenter >> sunCenterError;
                            
                            [dataPacket setSunCenter:[NSValue valueWithPoint:NSMakePoint(sunCenter.x(), sunCenter.y())]];
                            
                            for (int i = 0; i < NUM_LIMBS; i++) {
                                Pair3B limb;
                                tm_packet >> limb;
                                [dataPacket addChordPoint:NSMakePoint(limb.x(),limb.y()) :i];
                            }
                            
                            uint8_t nFiducials;
                            tm_packet >> nFiducials;
                            
                            uint8_t nLimbs;
                            tm_packet >> nLimbs;
                            
                            for (int i = 0; i < NUM_FIDUCIALS; i++) {
                                Pair3B fiducial;
                                tm_packet >> fiducial;
                                [dataPacket addFiducialPoint:NSMakePoint(fiducial.x(),fiducial.y()) :i];
                            }
                            
                            float x_intercept, x_slope;
                            tm_packet >> x_intercept >> x_slope;
                            
                            float y_intercept, y_slope;
                            tm_packet >> y_intercept >> y_slope;
                            
                            dataPacket.screenCenter = [NSValue valueWithPoint:NSMakePoint(-x_intercept/x_slope, -y_intercept/y_slope)];
                            dataPacket.screenRadius = 0.5* ((3000.0/fabs(x_slope)) + (3000.0/fabs(y_slope)));
                            
                            uint8_t image_max;
                            tm_packet >> image_max;
                            dataPacket.ImageMax = image_max;
                            
                            float ctl_xvalue, ctl_yvalue;
                            tm_packet >> ctl_xvalue >> ctl_yvalue;
                            [dataPacket setCTLCommand:[NSValue valueWithPoint:NSMakePoint(ctl_xvalue, ctl_yvalue)]];

                            for (int i = 0; i < NUM_FIDUCIALS; i++) {
                                uint8_t temp;
                                tm_packet >> temp;
                                int x_ID = ((int8_t)bitread(&temp,0,4))-7;
                                int y_ID = ((int8_t)bitread(&temp,4,4))-7;
                                [dataPacket addFiducialID:NSMakePoint(x_ID,y_ID) :i];
                            }
                        }
                        
                        if (tm_packet.getTypeID() == SAS_CM_ACK_TYPE) {
                            uint16_t sequence_number;
                            tm_packet >> sequence_number;
                            NSString *msg = [NSString stringWithFormat:@"Received ACK for command number %u", sequence_number];
                            [self postToLogWindow:msg:@"LogMessageACK"];
                        }
                        
                        if (tm_packet.getTypeID() == SAS_CM_PROC_ACK_TYPE) {
                            uint16_t sequence_number, command_key, return_code;
                            tm_packet >> sequence_number;
                            tm_packet >> command_key;
                            tm_packet >> return_code;
                            NSString *msg = [NSString stringWithFormat:@"Received PROC ACK for command number %u, command key 0x%X, return code %u", sequence_number, command_key, return_code];
                            [self postToLogWindow:msg:@"LogMessagePROCACK"];
                        }
                    }
                }
                delete packet;
                @autoreleasepool {
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: dataPacket, @"packet", nil];
                    if (![self isCancelled])
                        [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseDataDidFinish object:nil userInfo:info];
                }
            }
            // to make sure that info is released and does not cause a memory leak
                    }
    }
}

@end
