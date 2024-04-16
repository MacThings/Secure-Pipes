//
//  NESLocalForwardWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/21/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnectionWindowController.h"

@interface NESLocalForwardWindowController : NESConnectionWindowController


@property (weak) IBOutlet NSButton *toggleEnableBonjour;
@property (weak) IBOutlet NSTextField *bonjourServiceField;

@property (strong) IBOutlet NSPopUpButton *bindToDevice;
@end
