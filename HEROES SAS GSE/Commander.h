//
//  Commanding.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 1/13/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Commander : NSObject

- (void)send:(uint16_t) command_key: (uint16_t) command_value;

@end
