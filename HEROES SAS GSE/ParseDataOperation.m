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

#if true
#define DEFAULT_PORT 2003 /* The default port to send on */
#else
#define DEFAULT_PORT 2002
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

@interface ParseDataOperation(){
    UDPReceiver *tmReceiver;
}

@property (nonatomic, strong) DataPacket *dataPacket;
@property (nonatomic, strong) NSFileHandle *saveFile;

- (void)postToLogWindow: (NSString *)message;
@end

@implementation ParseDataOperation

@synthesize dataPacket = _dataPacket;
@synthesize saveFile = _saveFile;

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        tmReceiver = new TelemetryReceiver( DEFAULT_PORT );
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

- (NSFileHandle *)saveFile
{
    if (_saveFile == nil)
    {
        _saveFile = [[NSFileHandle alloc] init];
    }
    return _saveFile;
}

- (void)postToLogWindow: (NSString *)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:@"message"]];
}

- (void)OpenSaveFile{
    // Open a file to save the telemetry stream to
    
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
    //say to handle where's the file to write
    [self.saveFile truncateFileAtOffset:[self.saveFile seekToEndOfFile]];
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    @autoreleasepool {
        tmReceiver->init_connection();
        [self OpenSaveFile];
        
        while (1) {
            if ([self isCancelled])
            {
                tmReceiver->close_connection();
                free(tmReceiver);
                [self.saveFile closeFile];
                break;	// user cancelled this operation
            }
            
            uint16_t packet_length = tmReceiver->listen();
            if( packet_length != 0){
                uint8_t *packet = new uint8_t[packet_length];
                tmReceiver->get_packet( packet );
                
                //save to file
                [self.saveFile writeData:[NSData dataWithBytes:packet length:packet_length]];
                
                TelemetryPacket *tm_packet;
                tm_packet = new TelemetryPacket( packet, packet_length);
                
                if (tm_packet->valid())
                {
                    if (tm_packet->getSourceID() == SAS_TARGET_ID){
                        if (tm_packet->getTypeID() == SAS_TM_TYPE) {
                            
                            switch (tm_packet->getSAS()) {
                                case 1:
                                    self.dataPacket.isSAS1 = TRUE;
                                    break;
                                case 2:
                                    self.dataPacket.isSAS2 = TRUE;
                                    break;
                                default:
                                    self.dataPacket.isSAS1 = TRUE;
                                    break;
                            }
                            
                            [self.dataPacket setFrameSeconds: tm_packet->getSeconds()];
                            
                            uint32_t frame_number;
                            *(tm_packet) >> frame_number;
                            uint8_t status_bitfield;
                            *(tm_packet) >> status_bitfield;
                            
                            [self.dataPacket setFrameNumber: frame_number];
                            
                            //parse this bit field
                            self.dataPacket.isTracking = (bool)((status_bitfield & 128) >> 7);
                            self.dataPacket.isSunFound = (bool)((status_bitfield & 64) >> 6);
                            self.dataPacket.isOutputting = (bool)((status_bitfield & 32) >> 5);
                            self.dataPacket.isClockSynced = (bool)((status_bitfield & 16) >> 4);
                            self.dataPacket.aspectErrorCode = status_bitfield & 0xf;
                            
                            uint16_t command_key;
                            *(tm_packet) >> command_key;
                            [self.dataPacket setCommandKey: command_key];
                            
                            uint16_t housekeeping1, housekeeping2;
                            *(tm_packet) >> housekeeping1 >> housekeeping2;
                            
                            switch (frame_number % 8) {
                                case 0:
                                    self.dataPacket.cpuTemperature = (int16_t)housekeeping1;
                                    self.dataPacket.cameraTemperature = Float2B(housekeeping2).value();
                                    break;
                                case 1:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    self.dataPacket.cameraTemperature = Float2B(housekeeping2).value();
                                    break;
                                case 2:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    [self.dataPacket.sbcVoltages replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:(int16_t)housekeeping2]];
                                    break;
                                case 3:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    [self.dataPacket.sbcVoltages replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:(int16_t)housekeeping2]];
                                    break;
                                case 4:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    [self.dataPacket.sbcVoltages replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:(int16_t)housekeeping2]];
                                    break;
                                case 5:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:4 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    [self.dataPacket.sbcVoltages replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:(int16_t)housekeeping2]];
                                    break;
                                case 6:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:5 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    [self.dataPacket.sbcVoltages replaceObjectAtIndex:4 withObject:[NSNumber numberWithInt:(int16_t)housekeeping2]];
                                    break;
                                case 7:
                                    [self.dataPacket.i2cTemperatures replaceObjectAtIndex:6 withObject:[NSNumber numberWithInt:(int16_t)housekeeping1]];
                                    self.dataPacket.isSavingImages = housekeeping2;
                                default:
                                    break;
                            }
                            
                            Pair3B sunCenter, sunCenterError;
                            *(tm_packet) >> sunCenter >> sunCenterError;
                            
                            [self.dataPacket setSunCenter:[NSValue valueWithPoint:NSMakePoint(sunCenter.x(), sunCenter.y())]];
                            
                            for (int i = 0; i < NUM_LIMBS; i++) {
                                Pair3B limb;
                                *(tm_packet) >> limb;
                                [self.dataPacket addChordPoint:NSMakePoint(limb.x(),limb.y()) :i];
                            }
                            
                            uint8_t nFiducials;
                            *(tm_packet) >> nFiducials;
                            
                            uint8_t nLimbs;
                            *(tm_packet) >> nLimbs;
                            
                            for (int i = 0; i < NUM_FIDUCIALS; i++) {
                                Pair3B fiducial;
                                *(tm_packet) >> fiducial;
                                [self.dataPacket addFiducialPoint:NSMakePoint(fiducial.x(),fiducial.y()) :i];
                            }
                            
                            float x_intercept, x_slope;
                            *(tm_packet) >> x_intercept >> x_slope;
                            
                            float y_intercept, y_slope;
                            *(tm_packet) >> y_intercept >> y_slope;
                            
                            self.dataPacket.screenCenter = [NSValue valueWithPoint:NSMakePoint(-x_intercept/x_slope, -y_intercept/y_slope)];
                            self.dataPacket.screenRadius = 0.5* ((3000.0/fabs(x_slope)) + (3000.0/fabs(y_slope)));
                            
                            uint8_t image_max;
                            *(tm_packet) >> image_max;
                            
                            self.dataPacket.ImageMax = image_max;
                            
                            float ctl_xvalue, ctl_yvalue;
                            *(tm_packet) >> ctl_xvalue >> ctl_yvalue;
                            [self.dataPacket setCTLCommand:[NSValue valueWithPoint:NSMakePoint(ctl_xvalue, ctl_yvalue)]];
                        }
                        
                        if (tm_packet->getTypeID() == SAS_CM_ACK_TYPE) {
                            uint16_t sequence_number = 0;
                            *tm_packet >> sequence_number;
                            
                            NSString *msg = [NSString stringWithFormat:@"Received ACK for command number %u", sequence_number];
                            [self postToLogWindow:msg];
                        }
                        
                        if (tm_packet->getTypeID() == SAS_CM_PROC_ACK_TYPE) {
                            uint16_t sequence_number = 0;
                            *tm_packet >> sequence_number;
                            
                            uint16_t command_key = 0;
                            *tm_packet >> command_key;
                            
                            uint16_t return_code;
                            *tm_packet >> return_code;
                            //
                            NSString *msg = [NSString stringWithFormat:@"Received PROC ACK for command number %u, command key 0x%X, return code %u", sequence_number, command_key, return_code];
                            [self postToLogWindow:msg];
                        }
                    }
                }
                free(packet);
                free(tm_packet);
            }
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: self.dataPacket, @"packet", nil];
            if (![self isCancelled])
                [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseDataDidFinish object:nil userInfo:info];
        }
    }
}

@end
