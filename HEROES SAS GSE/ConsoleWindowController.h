//
//  ConsoleWindowController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConsoleWindowController : NSWindowController{
IBOutlet NSTextView *Console_TextView;
    int lineNumber;
}

@property (nonatomic) BOOL surpressACK;

- (IBAction)clear_button:(NSButton *)sender;
- (IBAction)copy_button:(NSButton*)sender;
- (IBAction)test_button:(NSButton *)sender;
- (IBAction)savetofile_button:(NSButton *)sender;

- (void) log:(NSString*) msg;

@end
