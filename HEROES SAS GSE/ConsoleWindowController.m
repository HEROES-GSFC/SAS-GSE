//
//  ConsoleWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "ConsoleWindowController.h"
#import "ConsoleTextView.h"

@interface ConsoleWindowController()
@end

@implementation ConsoleWindowController

- (id)init{
    lineNumber = 1;
    return [super initWithWindowNibName:@"ConsoleWindowController"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)button_action:(NSButton *)sender {
    [self log:@"boo"];
    [Console_TextView insertText:@"boo2"];
}

- (void) log:(NSString*) msg
{
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *lineHeader = [NSString stringWithFormat:@"[%03i %@] ",lineNumber,[dateFormatter stringFromDate:now]];
    
	NSRange endRange;
	endRange.location = [[Console_TextView textStorage] length];
	endRange.length = 0;
    NSString *text = [msg stringByAppendingString:@"\n"];
	[Console_TextView replaceCharactersInRange:endRange withString:[lineHeader stringByAppendingString:text]];
	endRange.length = [msg length];
	[Console_TextView scrollRangeToVisible:endRange];
    lineNumber++;

}

@end
