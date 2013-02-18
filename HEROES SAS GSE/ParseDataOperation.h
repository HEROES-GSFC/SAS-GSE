//
//  ParseDataOperation.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/28/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataPacket.h"
// NSNotification name to tell the Window controller an image file as found
extern NSString *kReceiveAndParseDataDidFinish;

@interface ParseDataOperation : NSOperation

@end
