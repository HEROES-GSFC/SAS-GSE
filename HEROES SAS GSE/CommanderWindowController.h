//
//  CommanderWindowController.h
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CommanderWindowController : NSWindowController
@property (weak) IBOutlet NSComboBox *comboBox;
@property (weak) IBOutlet NSTextField *commandKey_textField;

@end
