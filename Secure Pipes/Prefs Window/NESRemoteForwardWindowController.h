//
//  NESRemoteForwardWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/16/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnectionWindowController.h"

@interface NESRemoteForwardWindowController : NESConnectionWindowController


@property (strong) IBOutlet NSPopUpButton *bindToDevice;

@end
