//
//  NESProxyWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/19/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESProxyWindowController.h"
#import "NESUser.h"

@interface NESProxyWindowController ()

@end

@implementation NESProxyWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [super setType:NESConnectionProxy];
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
        allFields = [[NSArray alloc] initWithObjects:[ super nameField], [super sshUsernameField], [super bindDevice], [super sshServerField],  [super localAddressField], [super sshPortField], [super localPortField],
            [super sshIdentityField], [super httpProxyAddressField],  [super httpProxyPortField],
            [super scriptField], nil];
    }
    
    if (requiredFields == nil) {
        requiredFields = [[NSArray alloc] initWithObjects: [super nameField], [super sshUsernameField],  [super sshServerField], nil];
    }
    
    if (![[NESUser currentUser] isMemberOfAdminGroup]) {
        [[self autoConfigProxy] setState:NSOffState];
        [[self autoConfigProxy] setEnabled:NO];
    }
    
}

- (void) initWithConnection:(NESConnection *)conn {
    
    [super initWithConnection:conn];
    
    if (![[NESUser currentUser] isMemberOfAdminGroup]) {
        [[super autoConfigProxy] setEnabled:NO];
    }
        
}

- (IBAction)clickHelpButton:(id)sender {
    NESPopoverButton *button = [super autoConfigHelp];
    
    [button setPopoverDismissText:@"Close"];
    [button setPopoverMessage:@"When this option is enabled, the Network Preferences will automatically be configured to use the proxy when the connection is active. When the proxy connection is disconnected, the original settings will be restored. Please note this function requires administrative privileges."];
    [button showPopover];
    
}

@end
