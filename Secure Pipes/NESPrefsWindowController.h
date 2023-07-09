//
//  nesPrefsWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/9/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnection.h"
#import "NESConnectionViewController.h"
#import "NESGeneralViewController.h"
#import "NESController.h"
#import "NESAppConfig.h"

@class NESConnectionViewController;

@interface NESPrefsWindowController : NSWindowController <NSToolbarDelegate, NSOutlineViewDelegate> {

    NSViewController *infoViewController;
    NSView *currentView;
    
}

@property (weak)   NESController *controller;
@property (strong) NESConnectionViewController *connectionViewController;
@property (strong) NESGeneralViewController *generalViewController;
@property (strong) NESConnections  *connectionList;
@property (strong) NESAppConfig *appConfig;
@property (strong) NESConnectionManager *connectionManager;

@end
