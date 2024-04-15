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

#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

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
        allFields = [[NSArray alloc] initWithObjects:[ super nameField], [super sshUsernameField], [super bindDeviceField], [super sshServerField],  [super localAddressField],  [super remoteHostField],  [super sshPortField], [super localPortField],  [super remoteHostPortField], [super sshIdentityField], [super httpProxyAddressField], [super httpProxyPortField], [super scriptField], nil];
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

- (IBAction)listNetworkDevices:(id)sender {
    // Erstellen Sie einen leeren NSMutableString, um die Ausgabe zu sammeln
    NSMutableString *outputString = [NSMutableString string];
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    // Erhalten Sie die Liste der Netzwerkinterfaces
    if (getifaddrs(&interfaces) == 0) {
        // Durchlaufen Sie die Liste der Netzwerkinterfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) { // Überprüfen, ob es sich um eine IPv4-Adresse handelt
                // Holen Sie sich die IP-Adresse als Zeichenkette
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *ip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                
                // Überprüfen, ob die IP-Adresse gültig ist
                if (![ip isEqualToString:@"0.0.0.0"] && ![ip isEqualToString:@"127.0.0.1"]) {
                    // Formatieren Sie den Text und fügen Sie ihn zum outputString hinzu
                    NSString *outputLine = [NSString stringWithFormat:@"%@ (%@)\n", ip, name];
                    [outputString appendString:outputLine];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        freeifaddrs(interfaces); // Freigabe der Speicherressourcen
    }
    
    // Aktualisieren Sie das Fenster "Network Devices" mit dem outputString
    [self.listLokalNetworkDevices setStringValue:outputString];
    
    // Öffnen Sie das Fenster "Network Devices", wenn es nicht bereits geöffnet ist
    if (![self.listLokalNetworkDevicesWindow isVisible]) {
        [self.listLokalNetworkDevicesWindow makeKeyAndOrderFront:self];
    }
}





@end
