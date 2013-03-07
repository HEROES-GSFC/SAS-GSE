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
    
    NSString *text = [lineHeader stringByAppendingString:[msg stringByAppendingString:@"\n"]];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange selectedRange = NSMakeRange(0, [lineHeader length]); // 4 characters, starting at index 22
    
    [string beginEditing];
    [string addAttribute:NSFontAttributeName
                   value:[NSFont fontWithName:@"Helvetica-Bold" size:12.0]
                   range:selectedRange];
    [string endEditing];
    
    [[Console_TextView textStorage] insertAttributedString:string atIndex:[[Console_TextView string] length]];
    
    // scroll to bottom
    NSRange endRange;
	endRange.location = [[Console_TextView textStorage] length];
	endRange.length = 0;
	endRange.length = [text length];
	[Console_TextView scrollRangeToVisible:endRange];
    lineNumber++;
}

@end
