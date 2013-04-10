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
    TCPReceiver *tcpReceiver;
}

@property (nonatomic, strong) NSData *data;

@end


@implementation ParseTCPOperation

@synthesize data = _data;

- (id)init{
    self = [super init]; // call our super’s designated initializer
    if (self) {
        tcpReceiver = new TCPReceiver( TPCPORT_FOR_IMAGE_DATA );
    }
    return self;
}

- (NSData *)data{
    if (_data == nil) {
        _data = [[NSData alloc] init];
    }
    return _data;
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    @autoreleasepool {
        
        tcpReceiver->init_listen();
        
        int sock;
        while (1) {
            
            if ([self isCancelled])
            {
                NSLog(@"I am stopping too");
                break;	// user cancelled this operation
            }
            if((sock = tcpReceiver->accept_packet()) > 0){
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

                while ((packet_length = tcpReceiver->handle_tcpclient(sock)) > 0) {
                    uint8_t *packet;
                    packet = new uint8_t[packet_length];
                    tcpReceiver->get_packet( packet );
                    write(fileDescriptor, packet, packet_length);
                    free(packet);
                    packet_count++;
                }
                if (packet_count > 0) {
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
                    
                    self.data = [NSData dataWithBytes:image length:sizeof(uint8_t) * xpixels * ypixels];
                    
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: self.data, @"image", [NSNumber numberWithInt:xpixels], @"xsize", [NSNumber numberWithInt:ypixels], @"ysize", [NSNumber numberWithInt:imageMin], @"min", [NSNumber numberWithInt:imageMax], @"max", cameraName, @"camera", nil];
                    NSLog(@"Image min/max %d, %d", imageMin, imageMax);
                    if (![self isCancelled]){
                        [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveAndParseImageDidFinish object:nil userInfo:info];
                    }
                    close(fileDescriptor);
                    tcpReceiver->close_connection();
                }
            }
        }
    }
}

@end

