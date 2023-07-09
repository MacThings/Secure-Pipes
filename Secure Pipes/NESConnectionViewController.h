//
//  NESConnectionViewController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/16/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnection.h"
#import "NESManagedConnection.h"
#import "NESConfirmationSheet.h"
#import "NESEmptyView.h"
#import "NESConnectionManager.h"

#define GROUP_ROW_HEIGHT 30
#define CONNECTION_ROW_HEIGHT 40
#define FILTERBAR_HEIGHT 23

@class NESLocalForwardWindowController;
@class NESRemoteForwardWindowController;
@class NESProxyWindowController;
@class NESPrefsWindowController;
@class NESManagedConnectionWindowController;

@interface NESConnectionViewController : NSViewController  <NSOutlineViewDelegate, NSOutlineViewDataSource> {

    IBOutlet NSOutlineView *_outlineView;
    IBOutlet NSWindow *parentWindow;
    
    NESLocalForwardWindowController *localForwardController;
    NESRemoteForwardWindowController *remoteForwardController;
    NESProxyWindowController *proxyController;
    NESManagedConnectionWindowController *managedConnectionController;
    NESConnections *_rootContents;
    NESConfirmationSheet *confirmSheet;
    NESConnection *selectedConnection;
    BOOL canChangeSelection;
    NSTimer *updateTimer;
    NSTimeInterval updateInterval;
    
    NESConnectionManager *connectionManager;
    NSMutableDictionary *formatAttributes;
    
    NESNewManagedConnectionCommunicator *comm;
}

@property (weak) NESPrefsWindowController *prefsController;
@property (strong) NESConnections *rootContents;
@property (strong) NSWindow *prefsWindow;

- (void) doubleClickRow:(NSOutlineView *)sender;

- (IBAction)addLocalForward:(NSMenuItem *)sender;
- (IBAction)addRemoteForward:(NSMenuItem *)sender;
- (IBAction)addLocalProxy:(NSMenuItem *)sender;
- (IBAction)minusClicked:(NSButton *)sender;
- (IBAction)tableClicked:(NSOutlineView *)sender;
- (IBAction)editClicked:(NSButton *)sender;
- (void) expandList;
- (IBAction)filterClicked:(id)sender;

@property (strong) IBOutlet NSButton *minusButton;
@property (strong) IBOutlet NSPopUpButton *actionButton;

@property (weak) IBOutlet NSClipView *tableView;
@property (strong) IBOutlet NSScrollView *scrollView;
@property (strong) IBOutlet NESEmptyView *emptyView;
@property (strong) IBOutlet NSView *filterBar;
@property (strong) IBOutlet NSLayoutConstraint *filterHeightConstraint;
@property (strong) IBOutlet NSButton *filterAllButton;
@property (strong) IBOutlet NSButton *filterManagedButton;
@property (strong) IBOutlet NSButton *filterManualButton;

@property (strong) IBOutlet NSTextField *noConnectionText;


@end
