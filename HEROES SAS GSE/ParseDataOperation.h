//
//  ParseDataOperation.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 10/28/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataPacket.h"

extern NSString *kReceiveAndParseDataDidFinish;

@interface ParseDataOperation : NSOperation

- (id)initWithPort: (int)port;

@end
