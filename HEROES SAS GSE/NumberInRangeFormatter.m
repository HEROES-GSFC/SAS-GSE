//
//  NumberInRangeFormatter.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 5/23/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "NumberInRangeFormatter.h"

@implementation NumberInRangeFormatter

- (NSString *)stringForObjectValue:(id)anObject {
    
    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    return [NSString stringWithFormat:@"$%.2f", [anObject  floatValue]];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString  **)error {
    
    float floatResult;
    NSScanner *scanner;
    BOOL returnValue = NO;
    
    scanner = [NSScanner scannerWithString: string];
    [scanner scanString: @"$" intoString: NULL];    //ignore  return value
    if ([scanner scanFloat:&floatResult] && ([scanner isAtEnd])) {
        returnValue = YES;
        if (obj)
            *obj = [NSNumber numberWithFloat:floatResult];
    } else {
        if (error)
            *error = NSLocalizedString(@"Couldn’t convert  to float", @"Error converting");
    }
    return returnValue;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes{
    
}

@end
