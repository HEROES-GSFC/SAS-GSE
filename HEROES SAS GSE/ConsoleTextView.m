//
//  ConsoleTextView.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 1/28/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "ConsoleTextView.h"

@interface ConsoleTextView(){
@private
    int lineNumber;
}
@end

@implementation ConsoleTextView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        lineNumber = 0;
    }
    
    return self;
}

- (void)insertText:(id)insertString
{
    lineNumber++;
    
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *lineHeader = [NSString stringWithFormat:@"[%i %@] ",lineNumber,[dateFormatter stringFromDate:now]];
    
    NSString *text = [insertString stringByAppendingString:@"\n"];
    [super insertText:[lineHeader stringByAppendingString:text]];
}

@end
