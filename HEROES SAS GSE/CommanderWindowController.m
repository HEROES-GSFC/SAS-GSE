//
//  CommanderWindowController.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 2/27/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "CommanderWindowController.h"
#import "Commander.h"
#import "AppController.h"

@interface CommanderWindowController ()
@property (nonatomic,retain) NSDictionary *plistDict;
@property (nonatomic, strong) Commander *commander;
- (void)updateCommandKeyBasedonTargetSystem:(NSString *)target_system;
@end

@implementation CommanderWindowController

@synthesize commandListcomboBox;
@synthesize commandKey_textField;
@synthesize Variables_Form;
@synthesize destinationIP_textField;
@synthesize plistDict = _plistDict;
@synthesize commander = _commander;
@synthesize send_Button;
@synthesize targetListcomboBox;

- (id)init{
    return [super initWithWindowNibName:@"CommanderWindowController"];
}

- (Commander *)commander
{
    if (_commander == nil) {
        _commander = [[Commander alloc] init];
    }
    return _commander;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {

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
    [self.Variables_Form setHidden:YES];
    [self.send_Button setEnabled:NO];
    [self.confirm_Button setEnabled:NO];
    [self.targetListcomboBox selectItemAtIndex:0];

    [self.destinationIP_textField setStringValue:@"192.168.2.21"];    
}
- (IBAction)ConfirmButtonPushed:(NSButton *)sender {
    [self.send_Button setEnabled:YES];
}

- (IBAction)commandList_action:(NSComboBox *)sender {
    NSString *user_choice = [self.commandListcomboBox stringValue];
    NSString *command_key = [[self.plistDict valueForKey:user_choice] valueForKey:@"key"];
    [self.commandKey_textField setStringValue: command_key];
    
    [self updateCommandKeyBasedonTargetSystem:[self.targetListcomboBox stringValue]];
    
    NSArray *variable_names = [[self.plistDict valueForKey:user_choice] valueForKey:@"var_names"];
    NSInteger numberOfVariablesNeeded = [variable_names count];
    NSInteger numberOfVariablesCurrentlyDisplayed = (long)[self.Variables_Form numberOfRows];

    // clear the form of all elements
    for (int i = 0; i < numberOfVariablesCurrentlyDisplayed; i++) {
        [self.Variables_Form removeRow:0];
    }
    //NSLog(@"%ld", (long)[self.Variables_Form numberOfRows]);
    if (numberOfVariablesNeeded == 0) {
        [self.Variables_Form setHidden:NO];
    } else {
        for (NSString *name in variable_names) {
            [self.Variables_Form addEntry:name];
        }
        [self.Variables_Form setHidden:NO];
    }
    
    NSString *toolTip = (NSString *)[[self.plistDict valueForKey:user_choice] valueForKey:@"description"];
    [self.commandListcomboBox setToolTip:toolTip];
    [self.confirm_Button setEnabled:YES];
}

- (IBAction)ChoseTargetSystem:(NSComboBox *)sender {
    NSString *target_system = [sender stringValue];
    [self updateCommandKeyBasedonTargetSystem:target_system];
}

- (void)updateCommandKeyBasedonTargetSystem:(NSString *)target_system {
    NSString *command_key = [self.commandKey_textField stringValue];
    if ([target_system isEqualToString:@"SAS 1"]) {
        self.commandKey_textField.stringValue = [command_key stringByReplacingCharactersInRange:NSMakeRange(2, 1) withString:@"1"];
    }
    if ([target_system isEqualToString:@"SAS 2"]) {
        NSLog(@"%@", target_system);

        self.commandKey_textField.stringValue = [command_key stringByReplacingCharactersInRange:NSMakeRange(2, 1) withString:@"2"];
    }
    if ([target_system isEqualToString:@"Both"]) {
        self.commandKey_textField.stringValue = [command_key stringByReplacingCharactersInRange:NSMakeRange(2, 1) withString:@"3"];
    }
}

- (IBAction)send_Button:(NSButton *)sender {
    uint16_t command_sequence_number = 0;
    unsigned command_key;
    NSScanner *scanner = [NSScanner scannerWithString:[self.commandKey_textField stringValue]];
    [scanner scanHexInt:&command_key];
        
    NSInteger numberOfVariables = [self.Variables_Form numberOfRows];
    if (numberOfVariables == 0) {
        command_sequence_number = [self.commander send:(uint16_t)command_key :nil :[self.destinationIP_textField stringValue]];
    } else {
        NSMutableArray *variables = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < numberOfVariables; i++) {
            [variables addObject:[NSNumber numberWithInt:[[self.Variables_Form cellAtIndex:i] intValue]]];
        }
        command_sequence_number = [self.commander send:(uint16_t)command_key :variables :[self.destinationIP_textField stringValue]];
    }

    NSString *msg = [NSString stringWithFormat:@"sending (0x%04x, %@) command", (uint16_t)command_key, [self.commandListcomboBox stringValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:msg forKey:@"message"]];
    
    [self.commandCount_textField setIntegerValue:command_sequence_number];
    [self.send_Button setEnabled:NO];
    [self.confirm_Button setEnabled:NO];
}
@end
