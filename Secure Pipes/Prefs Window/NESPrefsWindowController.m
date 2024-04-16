//
//  nesPrefsWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/9/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESPrefsWindowController.h"

#define TOOLBAR_CONNECTIONS     @"TOOLBAR_CONNECTIONS"
#define TOOLBAR_GENERAL         @"TOOLBAR_GENERAL"
#define TOOLBAR_SPACE           @"TOOLBAR_SPACE"
#define TOOLBAR_INFO            @"TOOLBAR_INFO"

@interface NESPrefsWindowController ()


@end


@implementation NESPrefsWindowController

- (void)awakeFromNib {

    // NSLog(@"Window Controller Awake from NIB");
    

    // Make the toolbar
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"Prefs Toolbar"];
    
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [[self window] setToolbar: toolbar];
    
    // Load the different views
    //NSView *view;
    
    _connectionViewController = [[NESConnectionViewController alloc] initWithNibName:@"Connection View" bundle:nil];
    [_connectionViewController setPrefsWindow:[self window]];
    [_connectionViewController setPrefsController:self];
    [_connectionViewController setRootContents:_connectionList];
    currentView = [_connectionViewController view];
    [currentView setHidden:NO];
    [[[self window] contentView] addSubview: [_connectionViewController view]];

    _generalViewController = [[NESGeneralViewController alloc] initWithNibName:@"General View" bundle:nil];
    [_generalViewController setAppConfig:_appConfig];
    [_generalViewController setConnectionManager:_connectionManager];
    currentView = [_generalViewController view];
    [currentView setHidden:NO];
    [[[self window] contentView] addSubview: [_generalViewController view]];

    infoViewController = [[NSViewController alloc] initWithNibName:@"Info View" bundle:nil];
    currentView = [infoViewController view];
    [currentView setHidden:NO];
    [[[self window] contentView] addSubview: [infoViewController view]];
    
    currentView = [[self window] contentView];
    [toolbar setSelectedItemIdentifier:TOOLBAR_CONNECTIONS];
    [self setPrefsView:nil];

}

- (void) windowDidLoad {
//    NSLog(@"windowDidLoad");
}

//-(NESConnections *)connectionList {
//    
//    if (connectionViewController)
//        return [[connectionViewController view] subviews];
//    
//    return nil;
//}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString: TOOLBAR_CONNECTIONS]) {
        [item setLabel:NSLocalizedString(@"Connections", nil)];
        [item setImage: [NSImage imageNamed: NSImageNameNetwork]];
        [item setTarget: self];
        [item setAction: @selector(setPrefsView:)];
        [item setAutovalidates:NO];
    }
    else if ([itemIdentifier isEqualToString: TOOLBAR_GENERAL]) {
        [item setLabel:NSLocalizedString(@"General", nil)];
        [item setImage: [NSImage imageNamed: NSImageNamePreferencesGeneral]];
        [item setTarget: self];
        [item setAction: @selector(setPrefsView:)];
        [item setAutovalidates:NO];
    }
    else if ([itemIdentifier isEqualToString: TOOLBAR_INFO]) {
        [item setLabel:@"Info"];
        [item setImage: [NSImage imageNamed: NSImageNameInfo]];
        [item setTarget: self];
        [item setAction: @selector(setPrefsView:)];
        [item setAutovalidates:NO];
    }
    else {
        return nil;
    }
         
         return item;
    
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:TOOLBAR_CONNECTIONS, TOOLBAR_GENERAL, TOOLBAR_INFO, nil];
}

- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarAllowedItemIdentifiers: toolbar ];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarAllowedItemIdentifiers: toolbar ];
}

- (void) setPrefsView: (id) sender
{
    NSString *ident = (sender == nil)?TOOLBAR_CONNECTIONS:[sender itemIdentifier];

    NSView *view;
    if ([ident isEqualToString: TOOLBAR_CONNECTIONS]) {
        view = [_connectionViewController view];
    }
    else if ([ident isEqualToString: TOOLBAR_GENERAL]) {
        view = [_generalViewController view];
    }
    else if ([ident isEqualToString: TOOLBAR_INFO]) {
        view = [infoViewController view];
    } else
        return;

    if (currentView == view)
        return;
    
    // Switch the view...
    NSRect windowRect = [[self window] frame];
    const CGFloat difference = (NSHeight([view frame]) - NSHeight([currentView frame])) * [[self window] userSpaceScaleFactor];
    const CGFloat wdifference = (NSWidth([view frame]) - NSWidth([currentView frame])) * [[self window] userSpaceScaleFactor];
    windowRect.origin.y -= difference;
    windowRect.origin.x -= (wdifference/2);
    windowRect.size.height += difference;
    windowRect.size.width += wdifference;
    
    if (currentView != [[self window] contentView])
        [[currentView animator] setHidden:YES];
    [[[self window] animator] setContentView:view];
    [[self window] setFrame: windowRect display: YES animate: YES];
    [[view animator] setHidden:NO];
    currentView = view;
    
    // I can't seem to find a good place to put this in 
    if (view == [_connectionViewController view]) {
        [_connectionViewController expandList];
    }
    
}


@end
