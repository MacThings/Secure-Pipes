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
        allFields = [[NSArray alloc] initWithObjects:[ super nameField], [super sshUsernameField], [super bindDeviceField], [super sshServerField],  [super localAddressField], [super sshPortField], [super localPortField],
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

- (void) validateBindDeviceField:(NESPopoverTextField *)field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if ((name == nil) || ([name isEqualToString:@""])) {
        error = NSLocalizedString(@"If this field is left blank, \"localhost\" will be used for the default value. In this configuration, only local programs will have access to the forward via the loopback interface. If you would like to make the forward available to all hosts on your network, enter \"*\" to bind to all interfaces. Or, if you would like to bind to just one of this machine's specific IP addresses, you can enter it (or it\'s associated hostname).", nil);
        [field setButtonPopoverMessage:error withType:NESWarningPopover];
        return;
    } else if ((!([NESConnection isValidHost:name]||[NESConnection isValidIP:name]))&&(![name isEqualToString:@"*"])) {
        error = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" does not appear to be a valid IP or hostname. This value should be the hostname or IP address of an interface on this host. If you want only local programs to have access to the forward via the loopback interface, use \"localhost\" or 127.0.0.1 for the address (or leave the field blank). If you want all hosts on your network to have access to the forward, use \"*\".", nil),name];
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
        return;
    }
    
    [field setButtonHidden:YES];
}

- (IBAction)clickHelpButton:(id)sender {
    NESPopoverButton *button = [super autoConfigHelp];
    
    [button setPopoverDismissText:@"Close"];
    [button setPopoverMessage:NSLocalizedString(@"When this option is enabled, the Network Preferences will automatically be configured to use the proxy when the connection is active. When the proxy connection is disconnected, the original settings will be restored. Please note this function requires administrative privileges.", nil)];
    [button showPopover];
    
}

@end
