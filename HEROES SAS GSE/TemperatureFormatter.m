//
//  TemperatureFormatter.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 12/31/12.
//  Copyright (c) 2012 GSFC. All rights reserved.
//

#import "TemperatureFormatter.h"

@implementation TemperatureFormatter

- (NSString *)stringForObjectValue:(id)anObject {
    
    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    return [NSString stringWithFormat:@"%.2f", [anObject floatValue]];
}

- (NSAttributedString*) attributedStringForObjectValue: (id)anObject withDefaultAttributes: (NSDictionary*)attr;
{
    NSString *string = [self stringForObjectValue:anObject];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:string];
    NSInteger stringLength = [string length];
    
    if ([[attrString string] floatValue] < -20.0f) {
        [attrString addAttribute:@"NSForegroundColorAttributeName" value:[NSColor redColor] range:NSMakeRange(0, stringLength)];
        //NSLog(@"%@", attrString);
        return attrString;
    } else return attrString;
}


@end
