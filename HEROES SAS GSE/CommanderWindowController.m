//
//  CommanderWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "CommanderWindowController.h"

@interface CommanderWindowController ()

@end

@implementation CommanderWindowController

@synthesize comboBox = _comboBox;
@synthesize commandKey_textField;

- (id)init{
    return [super initWithWindowNibName:@"CommanderWindowController"];
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
    [self.commandKey_textField setStringValue:@"boo"];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
