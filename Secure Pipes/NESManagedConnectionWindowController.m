//
//  NESManagedConnectionWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 7/30/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESManagedConnectionWindowController.h"

NSString * const ticketRegex = TICKET_REGEX;

@interface NESManagedConnectionWindowController ()

@end

@implementation NESManagedConnectionWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [super setType:NESConnectionManaged];
        communicator = [[NESManagedConnectionCommunicator alloc] init];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
}

- (void) awakeFromNib {
    
    [super awakeFromNib];
    
    if (allFields == nil ) {
        allFields = [[NSArray alloc] initWithObjects:_ticketSegment1, _ticketSegment2,
                     _ticketSegment3, _ticketSegment4, nil];
    }
    
    if (requiredFields == nil) {
        requiredFields = [[NSArray alloc] initWithObjects:_ticketSegment1, _ticketSegment2,
                          _ticketSegment3, _ticketSegment4, nil];
    }
    
    [[self window] setInitialFirstResponder:_ticketSegment1];

}

- (void)controlTextDidEndEditing:(NSNotification *)notification {

    
}

-(NSArray *) ticketFormatMatches:(NSString *) string {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:ticketRegex options:NSRegularExpressionCaseInsensitive error:&error];
    
    return [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
}

-(void) clearTextFields {

    for (NSTextField *field in requiredFields) {
        [field setStringValue:@""];
    }
    
}

-(BOOL) checkValidTicketFormat {

    ticket = @"";
    
    // This assumes required fields are only ticket fields in sequence!
    for (NSTextField *field in requiredFields) {
        if ([field stringValue] != nil) {
            ticket = [ticket stringByAppendingFormat:@"%@-",[field stringValue]];
        }
    }
    
    ticket = [ticket substringToIndex:([ticket length]-1)];
    
    if ([[self ticketFormatMatches:ticket] count] > 0) {
        return YES;
    } else {
        return NO;
    }
        
}

-(BOOL)pastedTicketIsValid:(NSString *) string {
    
    // We can be a little forgiving...
    string = ticket = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([string length] != (TICKET_SEGMENTS*TICKET_SEGMENT_LENGTH)+(TICKET_SEGMENTS-1)) {
        return NO;
    }
    
    NSArray *matches = [self ticketFormatMatches:string];
    if ([matches count] == 1) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        int index = 1;
        // This assumes required fields are only ticket fields in sequence!
        for (NSTextField *field in requiredFields) {
            [field setStringValue:[string substringWithRange:[match rangeAtIndex:index++]]];
        }
        return YES;
    } else {
        return NO;
    }
    
    return NO;
}

-(void) controlTextDidChange:(NSNotification *)notification {

    NSTextField *inputField = [notification object];
    
    unichar lastDigit = [[inputField stringValue] characterAtIndex:([[inputField stringValue] length]-1)];
    // Check to make sure this is a digit
    if (![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:lastDigit]) {
        [inputField setStringValue:@""];
    }
    
    if ([[inputField stringValue] length] > (TICKET_SEGMENT_LENGTH-1)) {
        if ([[inputField stringValue] length] > TICKET_SEGMENT_LENGTH) {
            if ([self pastedTicketIsValid:[inputField stringValue]]) {
                [[inputField currentEditor] setSelectedRange:NSMakeRange(0, TICKET_SEGMENT_LENGTH)];
                goto setbutton;
            } else {
                [inputField setStringValue:@""];
                goto setbutton;
            }
        }
        
        [[self window] makeFirstResponder:[inputField nextKeyView]];
    }

setbutton:
    
    if ([self checkValidTicketFormat]) {
        [[self addButton] setEnabled:YES];
    } else {
        [[self addButton] setEnabled:NO];
    }

}

- (void) initWithConnection:(NESConnection *)conn {

    [super initWithConnection:conn];

    if (![[super config] objectForKey:@"managedConnectionServer"]) {
         [communicator setTicketServer:[appConfig configForKey:@"defaultManagedConnectionServer"]];
    }
    
    [[self addButton] setEnabled:NO];
    [[self progressIndicator] setHidden:YES];
    [self clearTextFields];
    
}

- (void) finishAddConnection {

    [[self myParent] endSheet:[self window] returnCode:NSModalResponseOK];
    [self clearTextFields];
    [[self progressIndicator] stopAnimation:self];
    connection = nil;
    
}

-(void) showErrorSheet: (NSString *) errorMessage {
    
    [_progressIndicator stopAnimation:self];
    [_progressIndicator setHidden:YES];
    confirmSheet = [[NESConfirmationSheet alloc] init];
    [confirmSheet setConfirmationText:errorMessage];
    [confirmSheet setParent:[self window]];
    [confirmSheet setCancelButtonHidden:YES];
    [[confirmSheet subImage] setImage:[NSImage imageNamed:NSImageNameCaution]];
    [[confirmSheet subImage] setHidden:NO];
    [[self window] beginCriticalSheet:[confirmSheet window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            //[[self myParent] endSheet:[self window] returnCode:NSModalResponseOK];
            //connection = nil;
        }
    }];
    // Completion routine will pass status to perform add (if confirmed), otherwise sheet just disappears.
    return;
    
    
}

- (IBAction)addConnection:(NSButton *)sender {

    [[self window] endEditingFor:nil];
    [[self progressIndicator] setHidden:NO];
    [[self progressIndicator] startAnimation:self];
    
    [communicator getConnectionConfigForTicket:ticket completionHandler:^(NSMutableDictionary *configData, NSString *errorString) {
        
        if (configData != nil) {
            [[self config] addEntriesFromDictionary:configData];
            [[self config] setObject:[communicator ticketServer] forKey:@"managedConnectionServer"];
            [self finishAddConnection];
        } else {
            [self showErrorSheet:errorString];
        }
        
    }];
    
}


@end
