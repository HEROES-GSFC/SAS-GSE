//
//  CommanderWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "CommanderWindowController.h"

@interface CommanderWindowController ()
@property (nonatomic,retain) NSDictionary *plistDict;
@end

@implementation CommanderWindowController

@synthesize commandListcomboBox;
@synthesize commandKey_textField;
@synthesize plistDict = _plistDict;

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

- (NSDictionary *)plistDict{
    if (_plistDict == nil) {
        // read command list dictionary from the CommandList.plist resource file
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CommandList" ofType:@"plist"];
        
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        
        _plistDict = (NSDictionary *)[NSPropertyListSerialization
                                                   propertyListFromData:plistXML
                                                   mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                   format:&format
                                                   errorDescription:&errorDesc];
        if (!_plistDict) {
            NSLog(@"Error reading CommandList.plist");
        }
    }
    return _plistDict;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.commandListcomboBox addItemsWithObjectValues:[self.plistDict allKeys]];
    [self.commandListcomboBox setCompletes:YES];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
}

- (IBAction)commandList_action:(NSComboBox *)sender {
    NSString *user_choice = [self.commandListcomboBox stringValue];
    [self.commandKey_textField setStringValue: [[self.plistDict valueForKey:user_choice] valueForKey:@"key"]];
}
@end
