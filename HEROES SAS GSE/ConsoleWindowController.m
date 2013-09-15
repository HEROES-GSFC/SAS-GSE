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
- (NSString *)createDateTimeString;
- (NSFileHandle *)openSaveFile;
@property (nonatomic, strong) NSFileHandle *saveFile;
@end

@implementation ConsoleWindowController

@synthesize surpressACK;

- (id)init{
    lineNumber = 1;
    self.surpressACK = TRUE;
    return [super initWithWindowNibName:@"ConsoleWindowController"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(print_notification:) name:@"LogMessage" object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(print_notification:) name:@"LogMessageACK" object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(print_notification:) name:@"LogMessagePROCACK" object:nil];
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
	[Console_TextView setString:@""];
}

- (IBAction)copy_button:(id)sender {
    [self copyToClipboard:[Console_TextView string]];
}

- (IBAction)test_button:(NSButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessageACK" object:nil userInfo:[NSDictionary dictionaryWithObject:@"My Test button was pushed" forKey:@"message"]];
}

- (IBAction)savetofile_button:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        if (self.saveFile == nil) {
            self.saveFile = [[NSFileHandle alloc] init];
            self.saveFile = [self openSaveFile];
        }
    } else {
        [self.saveFile closeFile];
        self.saveFile = nil;
    }
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
    
    if (self.saveFile) {
        [self.saveFile writeData:[[string string] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [[Console_TextView textStorage] insertAttributedString:string atIndex:[[Console_TextView string] length]];
    
    // scroll to bottom
    NSRange range;
    range = NSMakeRange ([[Console_TextView textStorage] length], 0);
	[Console_TextView scrollRangeToVisible:range];
    lineNumber++;
}

- (void) print_notification:(NSNotification *)note{
    NSDictionary *notifData = [note userInfo];
    NSString *name = [note name];
    NSString *message;
    message = [notifData valueForKey:@"message"];
    if ([name isEqualToString:@"LogMessageACK"] && !self.surpressACK) {
        [self log:message];
    }
    if ([name isNotEqualTo:@"LogMessageACK"]) {
        [self log:message];
    }
}

-(void)copyToClipboard:(NSString*)str
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [NSArray     arrayWithObjects:NSStringPboardType, nil];
    [pb declareTypes:types owner:self];
    [pb setString: str forType:NSStringPboardType];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"LogMessage" object:nil];
}

- (NSFileHandle *)openSaveFile{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"SAS-GSE-log_%@.txt", [self createDateTimeString]];
    
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    // open file to save data stream
    NSFileHandle *theFileHandle = [NSFileHandle fileHandleForWritingAtPath: filePath ];
    if (theFileHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        theFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    //say to handle where's the file fo write
    [theFileHandle truncateFileAtOffset:[theFileHandle seekToEndOfFile]];
    return theFileHandle;
}

- (NSString *)createDateTimeString{
    // Create a time string with the format YYYYMMdd_HHmmss
    // This can be used in file names (for example)
    //
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"YYYYMMdd_HHmmss"];
    
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    return dateString;
}

@end
