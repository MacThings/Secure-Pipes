//
//  NESProxyWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/19/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESProxyWindowController.h"
#import "NESUser.h"

#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

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
    
    NSArray<NSString *> *ipAddresses = [self getAvailableIPAddressesWithMenu:YES];
    
}

- (NSArray<NSString *> *)getAvailableIPAddressesWithMenu:(BOOL)createMenu {
    NSMutableArray<NSString *> *ipAddresses = [NSMutableArray array];
    
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
                    // Fügen Sie die IP-Adresse zur Liste hinzu
                    [ipAddresses addObject:[NSString stringWithFormat:@"(%@) %@", name, ip]];
                    
                    if (createMenu) {
                        // Fügen Sie den Menüeintrag hinzu
                        NSMenu *menu = self.bindToDevice.menu;
                        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"(%@) %@", name, ip] action:nil keyEquivalent:@""];
                        [menu addItem:menuItem];
                    }
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        freeifaddrs(interfaces); // Freigabe der Speicherressourcen
    }
    
    return ipAddresses;
}


- (IBAction)rescan_devices:(id)sender {
    NSMenu *menu = self.bindToDevice.menu;
    [menu removeAllItems];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"No", nil)] action:nil keyEquivalent:@""];
    [menu addItem:menuItem];
    
    NSArray<NSString *> *ipAddresses = [self getAvailableIPAddressesWithMenu:YES];
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
