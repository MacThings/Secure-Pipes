//
//  NESManagedRegistrationSheet.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/20/15.
//  Copyright (c) 2015 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESPopoverButton.h"

@interface NESManagedRegistrationSheet : NSWindowController <NSTextFieldDelegate>


@property (weak) NSWindow *parent;

- (IBAction)cancelClicked:(id)sender;
- (IBAction)registerClicked:(id)sender;
- (void) checkFields;
@property (strong) IBOutlet NSTextField *userNameField;
@property (strong) IBOutlet NSSecureTextField *passwordField;
@property (strong) IBOutlet NSSecureTextField *verifyField;
@property (strong) IBOutlet NESPopoverButton *helpButton;
@property (strong) IBOutlet NSButton *okayButton;

@end
