//
//  ConsoleWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "ConsoleWindowController.h"

@interface ConsoleWindowController()
-(void)copyToClipboard:(NSString*)str;
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

- (IBAction)clear_button:(id)sender {
    lineNumber = 0;

    // scroll to bottom
    NSRange endRange;
	endRange.location = 0;
	endRange.length = [[Console_TextView textStorage] length];
	[Console_TextView setString:@""];
}

- (IBAction)copy_button:(id)sender {
    [self copyToClipboard:[Console_TextView string]];
}

- (IBAction)test_button:(NSButton *)sender {
    [self log:@"My test button pushed."];
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
    NSRange range;
    range = NSMakeRange ([[Console_TextView textStorage] length], 0);
	[Console_TextView scrollRangeToVisible:range];
    lineNumber++;
}

-(void)copyToClipboard:(NSString*)str
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [NSArray     arrayWithObjects:NSStringPboardType, nil];
    [pb declareTypes:types owner:self];
    [pb setString: str forType:NSStringPboardType];
}

@end
