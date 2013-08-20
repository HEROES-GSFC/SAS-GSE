//
//  NumberInRangeFormatter.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 5/23/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NumberInRangeFormatter : NSFormatter

@property (nonatomic) float minimum;
@property (nonatomic) float maximum;

@end
