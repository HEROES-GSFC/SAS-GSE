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
@property (nonatomic, strong) NSDictionary *plistDict;
@property (nonatomic, strong) Commander *commander;
@property (nonatomic, strong) NSString *lastCommand;
- (void)updateCommandKeyBasedonTargetSystem:(NSString *)target_system;
@end

@implementation CommanderWindowController

@synthesize commandListcomboBox;
@synthesize commandKey_textField;
@synthesize Variables_Form;
@synthesize destinationIP_textField;
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
        // read command list dictionary from the CommandList.plist resource file
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        self.lastCommand = @"empty";
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CommandList" ofType:@"plist"];
        
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        self.plistDict = [[NSDictionary alloc] init];
        self.plistDict = (NSDictionary *)[NSPropertyListSerialization
                                      propertyListFromData:plistXML
                                      mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                      format:&format
                                      errorDescription:&errorDesc];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
        
    NSArray *sortedArray=[[self.plistDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.commandListcomboBox addItemsWithObjectValues:sortedArray];
    [self.commandListcomboBox setNumberOfVisibleItems:15];
    [self.commandListcomboBox setCompletes:YES];
    
    [self.send_Button setEnabled:NO];
    [self.confirm_Button setEnabled:YES];
    [self.targetListcomboBox selectItemAtIndex:0];
    [self.destinationIP_textField setStringValue:@"192.168.0.100"];
    
    for (int i = 0; i < [self.Variables_Form numberOfRows]; i++) {
        [[self.Variables_Form cellAtIndex:i] setEnabled:NO];
    }
}

-(void)controlTextDidChange:(NSNotification *)notification {
    id ax = NSAccessibilityUnignoredDescendant(self.commandListcomboBox);
    [ax accessibilitySetValue: [NSNumber numberWithBool: YES]
                 forAttribute: NSAccessibilityExpandedAttribute];
}

- (IBAction)ConfirmButtonPushed:(NSButton *)sender {
    [self.send_Button setEnabled:YES];
    [self.confirm_Button setEnabled:NO];
    [self.commandListcomboBox setEnabled:NO];
    [self.commandListcomboBox setTextColor:[NSColor redColor]];
    [self.targetListcomboBox setEnabled:NO];
}

- (IBAction)commandList_action:(NSComboBox *)sender {
    NSString *user_choice = [self.commandListcomboBox stringValue];
    if ([user_choice isEqualToString:self.lastCommand]) {
        NSLog(@"you've done this before!");
    } else {
        NSString *command_key = [[self.plistDict valueForKey:user_choice] valueForKey:@"key"];
        [self.commandKey_textField setStringValue: command_key];
    }
    [self updateCommandKeyBasedonTargetSystem:[self.targetListcomboBox stringValue]];
    
    NSArray *variable_names = [[self.plistDict valueForKey:user_choice] valueForKey:@"var_names"];
    NSInteger numberOfVariablesNeeded = [variable_names count];

    // clear the form of all elements
    for (int i = 0; i < [self.Variables_Form numberOfRows]; i++) {
        [[self.Variables_Form cellAtIndex:i] setEnabled:NO];
        [[self.Variables_Form cellAtIndex:i] setTitle:[NSString stringWithFormat:@"Field %i", i]];
        if (i < numberOfVariablesNeeded) {
            [[self.Variables_Form cellAtIndex:i] setEnabled:YES];
            [[self.Variables_Form cellAtIndex:i] setTitle:[variable_names objectAtIndex:i]];
        }
    }
    
    NSString *toolTip = (NSString *)[[self.plistDict valueForKey:user_choice] valueForKey:@"description"];
    [self.commandListcomboBox setToolTip:toolTip];
    [self.confirm_Button setEnabled:YES];
    // update the last command
    self.lastCommand = user_choice;
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
        command_sequence_number = [self.commander send:(uint16_t)command_key :[variables copy]:[self.destinationIP_textField stringValue]];
    }

    NSString *msg = [NSString stringWithFormat:@"sending (0x%04x, %@) command", (uint16_t)command_key, [self.commandListcomboBox stringValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:nil userInfo:[NSDictionary dictionaryWithObject:msg forKey:@"message"]];
    
    [self.commandCount_textField setIntegerValue:command_sequence_number];
    [self.send_Button setEnabled:NO];
    [self.confirm_Button setEnabled:NO];
    [self.Variables_Form setEnabled:YES];
    [self.commandListcomboBox setEnabled:YES];
    [self.targetListcomboBox setEnabled:YES];
    [self.destinationIP_textField setEnabled:YES];
    [self.commandListcomboBox setTextColor:[NSColor blackColor]];
}

- (IBAction)cancel_Button:(NSButton *)sender {
    [self.send_Button setEnabled:NO];
    [self.confirm_Button setEnabled:NO];
    [self.Variables_Form setEnabled:YES];
    [self.commandListcomboBox setEnabled:YES];
    [self.targetListcomboBox setEnabled:YES];
    [self.destinationIP_textField setEnabled:YES];
}
@end
