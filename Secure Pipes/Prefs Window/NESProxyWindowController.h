//
//  NESProxyWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/19/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnectionWindowController.h"

@interface NESProxyWindowController : NESConnectionWindowController

- (IBAction)clickHelpButton:(id)sender;


@property (strong) IBOutlet NSTextField *listLokalNetworkDevices;
@property (strong) IBOutlet NSWindow *listLokalNetworkDevicesWindow;
@property (strong) IBOutlet NSPopUpButton *bindToDevice;
@end
