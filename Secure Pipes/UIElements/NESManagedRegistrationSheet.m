//
//  NESManagedRegistrationSheet.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/20/15.
//  Copyright (c) 2015 Timothy Stonis. All rights reserved.
//

#import "NESManagedRegistrationSheet.h"

@interface NESManagedRegistrationSheet ()

@end

@implementation NESManagedRegistrationSheet

- (id) init {
    
    self = [super initWithWindowNibName:@"NESManagedRegistrationSheet"];
    
    if (self) {
        // Put initializers here.
        [self loadWindow];
        [_userNameField setDelegate:self];
        [_passwordField setDelegate:self];
        [_verifyField setDelegate:self];
        [self enableOkayButton];
    }
    
    return self;
}

-(void) enableOkayButton {
    
    NSString *username = [_userNameField stringValue];
    NSString *password = [_passwordField stringValue];
    NSString *verify = [_verifyField stringValue];
    
    if ((username)&&(password)&&(verify)) {
        
        if ([password isEqualToString:verify]&&(![username isEqualToString:@""])&(![password isEqualToString:@""])) {
            [_okayButton setEnabled:YES];
            return;
        }
    }

    [_okayButton setEnabled:NO];
    
}

-(void) awakeFromNib {
    
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSLog(@"Regi window awake (did load)...");
    
}

- (IBAction)registerClicked:(id)sender {

    [_parent endSheet:[self window] returnCode:NSModalResponseOK];

}

- (IBAction)cancelClicked:(id)sender {

    [_parent endSheet:[self window] returnCode:NSModalResponseCancel];

}

- (void) checkFields {
    
    [self enableOkayButton];
    
}

- (void) controlTextDidChange:(NSNotification *)obj {
    NSTextField *field = [obj object];
    
    
    // TODO: Need to limit length of these things. 
    if (field == _userNameField) {
        NSLog(@"Username");
    } else if (field == _passwordField) {
        NSLog(@"Password");
    } else if (field == _verifyField) {
        NSLog(@"Verify");
    }
    
    [self enableOkayButton];
    
}


@end
