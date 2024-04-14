//
//  NESLocalForwardWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/21/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESLocalForwardWindowController.h"
#import "NESPopoverTextField+FirstResponderNotification.h"
#import "NESConnection.h"
#import "NESUser.h"
#include "netdb.h"

@interface NESLocalForwardWindowController ()

@end

@implementation NESLocalForwardWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [super setType:NESConnectionLocalForward];
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
        allFields = [[NSArray alloc] initWithObjects:[ super nameField], [super sshUsernameField], [super bindDevice], [super sshServerField],  [super localAddressField],  [super remoteHostField],  [super sshPortField], [super localPortField],  [super remoteHostPortField], [super sshIdentityField], [super httpProxyAddressField], [super httpProxyPortField], [super scriptField], nil];
    }
    
    if (requiredFields == nil) {
        requiredFields = [[NSArray alloc] initWithObjects: [super nameField], [super sshUsernameField],  [super sshServerField], [super remoteHostField], nil];
    }
    
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
 
    [super controlTextDidEndEditing:notification];

    NESPopoverTextField *field = [notification object];
    
    if ((field == [super remoteHostPortField])||(field == [super localPortField])) {
        [self guessBonjourServiceName];
    }
    
}

- (void) guessBonjourServiceName {

    NSMutableDictionary *config = [super config];
    if ([config objectForKey:@"useBonjour"] == nil) {
        // For Bonjour, most likely the remote service is the "real" port number.
        uint16 port = htons((uint16_t)[[config objectForKey:@"remotePort"] integerValue]);
        struct servent *service = getservbyport(port,"tcp");
        if (!service) {
            port = htons((uint16_t)[[config objectForKey:@"localBindPort"] integerValue]);
            service = getservbyport(port,"tcp");
        }
        
        if (service) {
            [config setObject:[NSString stringWithUTF8String:service->s_name] forKey:@"bonjourServiceName"];
        }
    }
}

- (void) initWithConnection:(NESConnection *)conn {
    
    [super initWithConnection:conn];

    [self guessBonjourServiceName];
    
}


@end
