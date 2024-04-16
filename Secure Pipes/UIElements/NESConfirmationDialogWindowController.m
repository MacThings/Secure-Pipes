//
//  NESConfirmationDialogWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 4/5/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConfirmationDialogWindowController.h"

@interface NESConfirmationDialogWindowController ()

@end

@implementation NESConfirmationDialogWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id) init {

    self = [super initWithWindowNibName:@"NESConfirmationDialogWindow"];
    
    if (self) {
        // Put initializers here.
        [self loadWindow];
    }
    
    return self;
    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)cancelClicked:(id)sender {
    
    [NSApp stopModalWithCode:NSModalResponseCancel];
    
}

- (IBAction)okayClicked:(id)sender {
        
    [NSApp stopModalWithCode:NSModalResponseOK];
    
}

- (void)setConfirmationText:(NSString *)confirmationText {
    
    [_confirmationTextField setStringValue:confirmationText];
    
}

- (void) setSubText:(NSString *)subText {
    
    [_subTextField setStringValue:subText];
    
}

@end
