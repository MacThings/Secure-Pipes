//
//  NESAdminPasswordDialogWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/11/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESAdminPasswordDialogWindowController.h"

@interface NESAdminPasswordDialogWindowController ()

@end

@implementation NESAdminPasswordDialogWindowController

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib {
    
    [_passwordField setStringValue:@""];
    
}

- (id) init {
    
    self = [super initWithWindowNibName:@"NESAdminPasswordDialog"];
    
    if (self) {
        // Put initializers here.
        [self loadWindow];
    }
    
    return self;
}

- (void) setConfirmationText:(NSString *)confirmationText {
    [_confirmationTextField setStringValue:confirmationText];
    
}

- (void) setConfirmButtonText:(NSString *)confirmButtonText {
    [_confirmButton setStringValue:confirmButtonText];
}

- (void) setCancelButtonText:(NSString *)cancelButtonText {
    [_cancelButton setStringValue:cancelButtonText];
    //setNameFieldText
}

- (void) setNameFieldText:(NSString *)nameFieldText {
    [_nameField setStringValue:nameFieldText];
}


- (void) setWindowImage:(NSImage *)windowImage {
    [_image setImage:windowImage];
}

- (IBAction)cancelClicked:(id)sender {
    
    [NSApp stopModalWithCode:NSModalResponseCancel];
    
}

- (IBAction)okayClicked:(id)sender {
    
    if ([_saveCheckBox integerValue]) {
        // Put the password in the key chain.
        if ([NESKeychain keyChainItemExists:APP_NAME withType:0]) {
            [NESKeychain updateKeyChainItem:APP_NAME withName:APP_NAME andUser:NSUserName() andPassword:[_passwordField stringValue] andType:0];
        } else {
            [NESKeychain addKeyChainItem:APP_NAME withUser:NSUserName() andPassword:[_passwordField stringValue] andType:0];
        }
    } else {
        [NESKeychain removeKeyChainItem:APP_NAME andType:0];
    }
    
    [NSApp stopModalWithCode:NSModalResponseOK];
    
}

- (NSString *)password {
    return [_passwordField stringValue];
}

- (void) enableSavePassword:(BOOL)enable {

    [_saveCheckBox setEnabled:enable];

    if (!enable) {
        [_saveCheckBox setState:NO];
    }
    
    
}

@end
