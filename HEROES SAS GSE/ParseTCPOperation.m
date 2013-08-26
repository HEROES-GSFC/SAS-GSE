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
#import "Image.hpp"
#include <unistd.h>

#define PAYLOAD_SIZE
#define DEFAULT_PORT 5010 /* The default port to send on */

#define SAS_TARGET_ID 0x30
#define SAS_TM_TYPE 0x70
#define SAS_IMAGE_TYPE 0x82
#define SAS_SYNC_WORD 0xEB90
#define SAS_CM_ACK_TYPE 0x01
#define TPCPORT_FOR_IMAGE_DATA 2013

// NSNotification name to tell the Window controller an image file as found
NSString *kReceiveAndParseImageDidFinish = @"ReceiveAndParseImageDidFinish";

@interface ParseTCPOperation(){
}
@end

@implementation ParseTCPOperation

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {

    }
    return self;
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    TCPReceiver tcpReceiver = TCPReceiver( TPCPORT_FOR_IMAGE_DATA );
    @autoreleasepool {
        tcpReceiver.init_listen();
        NSData *data = [[NSData alloc] init];
        int sock;
        while (1) {
            
            if ([self isCancelled])
            {
                // user cancelled this operation
                tcpReceiver.close_connection();
                tcpReceiver.close_listen();
                NSLog(@"Stopping TCP listener and parser");
                break;
            }
            
            if((sock = tcpReceiver.accept_packet()) > 0){
                NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"myapptempfile.XXXXXX"];
                const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
                char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
                strcpy(tempFileNameCString, tempFileTemplateCString);
                int fileDescriptor = mkstemp(tempFileNameCString);
                
                NSString *tempFileName =
                [[NSFileManager defaultManager]
                 stringWithFileSystemRepresentation:tempFileNameCString
                 length:strlen(tempFileNameCString)];
                free(tempFileNameCString);
                int packet_count = 0;
                int packet_length;
                
                while ((packet_length = tcpReceiver.handle_tcpclient(sock)) > 0) {
                    uint8_t *packet;
                    packet = new uint8_t[packet_length];
                    tcpReceiver.get_packet( packet );
                    write(fileDescriptor, packet, packet_length);
                    free(packet);
                    packet_count++;
                }
                if (packet_count > 1) {
                    NSString *cameraName;
                    
                    ImagePacketQueue ipq;
                    ipq.filterSourceID(0x30);
                    ipq.add_file([tempFileName UTF8String]);
                    packet_count = (int)ipq.size();
                    
                    uint8_t camera;
                    uint16_t xpixels;
                    uint16_t ypixels;
                    std::vector<uint8_t> output;
                    ipq.reassembleTo(camera, xpixels, ypixels, output);
                    
                    if (camera == 1) {
                        cameraName = @"PYAS-F";
                    }
                    if (camera == 2) {
                        cameraName = @"PYAS-R";
                    }
                    if (camera == 6) {
                        cameraName = @"RAS";
                    }
                    
                    uint8_t *image = (uint8_t *)&output[0];
                    
                    uint8_t imageMax, imageMin;
                    imageMax = 0;
                    imageMin = 255;
                    
                    for (long ii = 0; ii < xpixels*ypixels; ii++) {
                        if (imageMax < *(image+ii)) imageMax = *(image+ii);
                        if (imageMin > *(image+ii)) imageMin = *(image+ii);
                    }
                    
                    NSString *LogMessageNSLog = [NSString stringWithFormat:@"received %d image packets, image size is %dx%d", packet_count, xpixels, ypixels];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:LogMessageNSLog forKey:@"message"]];
                    
                    @autoreleasepool {
                        data = [NSData dataWithBytes:image length:sizeof(uint8_t) * xpixels * ypixels];
                        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: data, @"image", [NSNumber numberWithInt:xpixels], @"xsize", [NSNumber numberWithInt:ypixels], @"ysize", [NSNumber numberWithInt:imageMin], @"min", [NSNumber numberWithInt:imageMax], @"max", cameraName, @"camera", nil];

                        if (![self isCancelled]){
                            [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseImageDidFinish object:nil userInfo:info];
                        }
                    }
                    close(fileDescriptor);
                    tcpReceiver.close_connection();
                }
            }
        }
    }
}

@end

