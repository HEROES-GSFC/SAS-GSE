//
//  ConsoleWindowController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConsoleTextView.h"

@interface ConsoleWindowController : NSWindowController{
IBOutlet NSTextView *Console_TextView;
    int lineNumber;
}



- (void) log:(NSString*) msg;

@end
