//
//  NESConnectionViewController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/16/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnectionViewController.h"
#import "NESConnectionCellView.h"
#import "NESConnectionWindowController.h"
#import "NESLocalForwardWindowController.h"
#import "NESRemoteForwardWindowController.h"
#import "NESProxyWindowController.h"
#import "NESManagedConnectionWindowController.h"
#import "NESPrefsWindowController.h"
#import "NESController.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation NESConnectionViewController

- (void)awakeFromNib {

    if (!_rootContents) {
        _rootContents = [[NESConnections alloc] init];
        [_rootContents loadConnections];
        [_outlineView reloadData];
        [_minusButton setEnabled:NO];
        [_actionButton setEnabled:NO];
        [_outlineView setDoubleAction:@selector(doubleClickRow:)];
    }
    
    if (localForwardController == nil) {
        localForwardController = [[NESLocalForwardWindowController alloc] initWithWindowNibName:@"LocalForwardWindow"];
        [localForwardController loadWindow];
        [localForwardController setConnectionController:self];
    }
    
    if (remoteForwardController == nil) {
        remoteForwardController = [[NESRemoteForwardWindowController alloc] initWithWindowNibName:@"RemoteForwardWindow"];
        [remoteForwardController loadWindow];
        [remoteForwardController setConnectionController:self];
    }

    if (proxyController == nil) {
        proxyController = [[NESProxyWindowController alloc] initWithWindowNibName:@"ProxyWindow"];
        [proxyController loadWindow];
        [proxyController setConnectionController:self];
    }

    if (managedConnectionController == nil) {
        managedConnectionController = [[NESManagedConnectionWindowController alloc] initWithWindowNibName:@"ManagedConnectionWindow"];
        formatAttributes = [[NSMutableDictionary alloc] initWithDictionary:
                            @{ NSSuperscriptAttributeName : @1,
                               NSForegroundColorAttributeName : [NSColor colorWithSRGBRed:0.27 green:0.37 blue:0.83 alpha:.85],
                               NSFontAttributeName : [NSFont boldSystemFontOfSize:7.0]}];

        [managedConnectionController loadWindow];
        [managedConnectionController setConnectionController:self];
        //[self checkForUpdates];
    }
    
    if (connectionManager == nil) {
        connectionManager = [_prefsController connectionManager];
        if (connectionManager) {
            [connectionManager addObserver:self forKeyPath:@"registered" options:NSKeyValueObservingOptionNew context:nil];
        }
    }

    [_emptyView setHidden:YES];
    [_emptyView setFillColor:[[_noConnectionText cell] backgroundColor]];
    [_tableView addSubview:_emptyView];    
    
    [self showFilterBarIfNeeded];
    [_outlineView setDoubleAction:@selector(doubleClickRow:)];
    [self selectConnection:nil];
    
    [self checkNeedsEmptyTable];

}

- (void) checkForUpdates {
    
    if ([_rootContents hasManagedConnections]) {
        
        // If any editing is going on, just check later...
        if ([[_prefsWindow sheets] count] > 0) {
            [self armUpdateTimer];
            return;
        }
        
        [_rootContents checkManagedConnectionsForUpdates:^(NSMutableDictionary *config) {

            if (config) {
                NSLog(@"%@ needs an update!",[config objectForKey:@"UUID"]);
                [config setObject:@true forKey:@"managedConnection"];
                NESManagedConnection *oldConnection = (NESManagedConnection *)[_rootContents findConnectionWithUUID:[config objectForKey:@"UUID"]];
                // This is a bit of a hack, but resuses same code as the dialog...
                NESManagedConnection *newConnection = (NESManagedConnection *)[self finishAddEditConnection:NSModalResponseOK asType:[oldConnection type] connectionName:[oldConnection name] withConfig:config];
                
                [newConnection configUpdated:oldConnection];
                
            }
            
            [self armUpdateTimer];
        
        }];
    }
    
}

- (void) armUpdateTimer {

    updateInterval = [[[_prefsController appConfig] configForKey:@"managedConnectionUpdateInterval"] doubleValue];
    
    NSLog(@"Update Interval is: %f seconds",updateInterval);
    
    updateTimer = [NSTimer timerWithTimeInterval:updateInterval target:self selector:@selector(updateTimerExpired:) userInfo:self repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:updateTimer forMode:NSDefaultRunLoopMode];
    
}

- (void) updateTimerExpired:(NSTimer *) timer {
    
    NSLog(@"Timer fired!");
    [self checkForUpdates];
    
}


- (void) checkNeedsEmptyTable {
    
    if ([[_rootContents children] count] == 0) {
        [_emptyView setHidden:NO];
        [[_outlineView animator] setHidden:YES];
    } else {
        if ([_outlineView isHidden]) {
            [_emptyView setHidden:YES];
            [[_outlineView animator] setHidden:NO];
        }
    }
    
}

- (void) expandList {
    int count = 0;

    for (NESConnection *container in [_rootContents children]) {
        count += [[container children] count];
        if (count<5) {
            [_outlineView expandItem:container];
        } else
            break;
    }
    
//    if ([[_rootContents children] count] == 1) {
//        [_outlineView expandItem: [[_rootContents children] objectAtIndex:0]];
//    }
}

- (void) showFilterBarIfNeeded {
    
    if ([_rootContents hasManagedConnections] && [_rootContents hasUnManagedConnections]) {
        [self hideFilterBar:YES withAnimation:YES];
    } else {
        [self hideFilterBar:YES withAnimation:YES];
    }
    
}

- (void) hideFilterBar: (BOOL)hide withAnimation: (BOOL)animate {
    int newHeight = 0;
    
    if (!hide)  {
        newHeight = FILTERBAR_HEIGHT;
    }
    
    if (animate) {
        [_filterHeightConstraint.animator setConstant:newHeight];
    } else {
        [_filterHeightConstraint setConstant:newHeight];
    }
    
}

- (IBAction)filterClicked:(id)sender {

//    static BOOL show = false;
//    
//    if (show) {
//        [self hideFilterBar:YES withAnimation:YES];
//    } else {
//        [self hideFilterBar:NO withAnimation:YES];
//    }
//    
//    show = !show;
    
    
    // Add managed connection (TODO):
    // 1) Create new connection type and holder
    // 2) Add filter bar
    /*
    if (selectedConnection) {
        NSLog(@"Have one!");
//        NESManagedConnection *test = [[NESManagedConnection alloc] initWithName:[selectedConnection name] asType:[selectedConnection type] andConfig:[selectedConnection connectionConfig]];
        comm = [[NESNewManagedConnectionCommunicator alloc] init];
        [comm setTicketServer:@"https://www.opoet.com/ticket"];
        //[comm setTicketServer:@"http://localhost:8888"];
        CFStringRef hostname = SCDynamicStoreCopyComputerName ( nil, nil );
        NSLog(@"Hostname: %@", (__bridge NSString *)hostname);
        CFRelease(hostname);
        [comm connect:^(BOOL success, NSString *error) {
            if (!success) {
                NSLog(@"Call to connect failed: %@",error);
            } else
                NSLog(@"Call to connect suceeded.");
        }];
    } */
    [connectionManager setRegistered:YES];
    
}

-(NESConnections *)rootContents {
    return _rootContents;
}

-(void)setRootContents:(NESConnections *)connections {

    _rootContents = connections;
    [connections addObserver:self forKeyPath:@"statusUpdated" options:NSKeyValueObservingOptionNew context:nil];
    [_outlineView reloadData];
    
}

#pragma mark NSOutline selectors

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    
    if (selectedConnection) {
        if ([outlineView parentForItem:selectedConnection] == item) {
            [_outlineView deselectRow:[_outlineView selectedRow]];
            [_minusButton setEnabled:NO];
            [_actionButton setEnabled:NO];
        }
    }
    return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    if (item == nil) {
        return [[_rootContents children] count];
    } else
        return [[item children] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    //NSLog(@"OutlineView isitemexpandable called");
    if ([(NESConnection *)item type] == NESConnectionContainer)
        return YES;
    else
        return NO;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([(NESConnection *)item type] == NESConnectionContainer)
        return GROUP_ROW_HEIGHT;
    else
        return CONNECTION_ROW_HEIGHT;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {

    if ([(NESConnection *)item type] == NESConnectionContainer)
        return YES;
    else
        return NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    //NSLog(@"OutlineView child at index %ld called",(long)index);
    if (item != nil) {
        //NSLog(@"Returning string: %@",[[item children] objectAtIndex:index]);
        return [[item children] objectAtIndex:index];
    } else
        return [[_rootContents children] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {

    //NSLog(@"OutlineView objectValueForTableColumn %@ called",[tableColumn identifier]);
    
//    if (item == nil) {
//        return nil;
//    }
//    else
//        return [item name];
    return item;
}

- (NSColor *) colorForManagedStatus:(NESConnection *)connection {
    
    if (connectionManager) {
        if (![connectionManager registered]) {
            return [NSColor lightGrayColor];
        } else {
            return [NSColor colorWithSRGBRed:0.27 green:0.37 blue:0.83 alpha:.85];
        }
    } else {
        return [NSColor lightGrayColor];
    }
    
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NESConnection *)item {

    if ( [item type] == NESConnectionContainer ) {
        NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"GroupCell" owner:self];
        [[cellView textField] setStringValue:[item name]];
        return cellView;
    }
    else {
        NESConnectionCellView *cellView = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];

        if ([item isManaged]) {
            [formatAttributes setObject:[self colorForManagedStatus:item] forKey:NSForegroundColorAttributeName];
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:@" MANAGED" attributes:formatAttributes];
            NSMutableAttributedString *final = [[NSMutableAttributedString alloc] initWithString:[item name]];
            [final appendAttributedString:string];
            [cellView.connectionName setAttributedStringValue:final];
        } else {
            [cellView.connectionName setStringValue:[item name]];
        }
        
        [cellView.serverName setStringValue:[item verboseDescription:NO]];
        [cellView.serverName setToolTip:[item verboseDescription:NO]];
        [cellView.statusLight setImage:[NESConnection imageForStatus:(NESConnectionStatus)[item status]]];
        
        if (([item status]&NESConnectionUpdatingConfig)&&([cellView.infoPopupButton isHidden])) {
            [cellView.busyIndicator setHidden:NO];
            [cellView.busyIndicator startAnimation:item];
        } else {
            [cellView.busyIndicator setHidden:YES];
            [cellView.busyIndicator stopAnimation:item];
        }
        if ([item status]&NESConnectionError) {
            [cellView.infoPopupButton setTitle:@"!"];
            [cellView.infoPopupButton setHidden:NO];
            [cellView.infoPopupButton setTarget:self];
            [cellView.infoPopupButton setAssociatedObject:item];
            [cellView.infoPopupButton setPopoverMessage:[NSString stringWithFormat:@"Error: %@",[item statusForKey:@"message"]]];
            [cellView.infoPopupButton setAction:@selector(showErrorPopup:)];
        } else if ([item status]&NESConnectionSyncFailure) {
            [cellView.infoPopupButton setTitle:@"i"];
            [cellView.infoPopupButton setHidden:NO];
            [cellView.infoPopupButton setTarget:self];
            [cellView.infoPopupButton setAssociatedObject:item];
            [cellView.infoPopupButton setPopoverMessage:[NSString stringWithFormat:@"Warning: %@",[item statusForKey:@"syncMessage"]]];
            [cellView.infoPopupButton setAction:@selector(showWarningPopup:)];
        } else {
            [cellView.infoPopupButton setHidden:YES];
        }
        return cellView;
    }
    
    return nil;
    
}

- (void) showWarningPopup:(NESPopoverButton *) sender  {
    NESConnection *connection = [sender associatedObject];
    
//    [sender setPopoverMessage:[NSString stringWithFormat:@"Warning: %@",[connection statusForKey:@"message"]]];
    
    [sender setCompletionHandler:^{
        [connection queueStatusUpdate:NESConnectionSyncOk withData:@"Error cleared"];
    }];
    
    [sender showPopover];
}


- (void) showErrorPopup:(NESPopoverButton *) sender  {
    NESConnection *connection = [sender associatedObject];
    
    //[sender setPopoverMessage:[NSString stringWithFormat:@"Error: %@",[connection statusForKey:@"message"]]];
    
    [sender setCompletionHandler:^{
        [connection queueStatusUpdate:NESConnectionIdle withData:@"Error cleared"];
    }];
    
    [sender showPopover];    
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    
}

- (BOOL) updateConnection:(NESConnection *)connection forName:(NSString *) name {
    
    NSArray *moveSet = [_rootContents updateConnection:connection forName:name];
    
    NESConnection *parent = [[_rootContents children] objectAtIndex:[[_rootContents indexForConnectionTypeContainer:[connection type]] firstIndex]];

    [_outlineView moveItemAtIndex:[(NSIndexSet *)[moveSet objectAtIndex:0] firstIndex] inParent:parent toIndex:[(NSIndexSet *)[moveSet objectAtIndex:1] firstIndex] inParent:parent];
    
    [_outlineView reloadItem:parent reloadChildren:YES];

    return YES;
}


- (BOOL) addConnection:(NESConnection *) connection {

    NSIndexSet *index = [_rootContents indexForConnectionTypeContainer: (int)[connection type]];
    
    //First let's deal with the container
    if ( index == nil) {
        BOOL hasManagedConnectionsBefore = [_rootContents hasManagedConnections];
        
        // Create container and add to view
        index = [_rootContents addContainerForConnectionType:(int)[connection type]];
        [self checkNeedsEmptyTable];
        [_outlineView beginUpdates];
        [_outlineView insertItemsAtIndexes:index inParent:nil withAnimation:NSTableViewAnimationSlideLeft];
        [_outlineView endUpdates];
        
        // If we now have managed connections, we need to start the update process...
        if (([_rootContents hasManagedConnections]) && (!hasManagedConnectionsBefore)) {
            [self armUpdateTimer];
        }
        
    }
    
    NESConnection *container = [[_rootContents children] objectAtIndex:[index firstIndex]];
    
    // If the container is not expanded, expand it so we can see our new connection
    [_outlineView expandItem:container];
    
    // Add the connection...
    index = [_rootContents addConnection:connection];
    [_outlineView beginUpdates];
    [_outlineView insertItemsAtIndexes:index inParent:container withAnimation:NSTableViewAnimationSlideLeft];
    [_outlineView endUpdates];
    [_outlineView reloadItem:container reloadChildren:YES];
    
    [self selectConnection:selectedConnection];
    [self showFilterBarIfNeeded];
    
    return YES;
                  
}

- (NESConnection *) finishAddEditConnection: (NSModalResponse) returnCode asType:(NSInteger)type connectionName:(NSString *)editName withConfig:(NSDictionary *) config {
    
    if (returnCode != NSModalResponseCancel) {
        NSString *name = [config valueForKey:@"name"];
        NESConnection *connection;
        if ([[config valueForKey:@"managedConnection"] boolValue]) {
            connection = [[NESManagedConnection alloc] initWithName:name asType:type andConfig:config];
        } else {
            connection = [[NESConnection alloc] initWithName:name asType:type andConfig:config];
        }
        if (editName) {
            [self updateConnection:connection forName:editName];
            // This seems strange, but the update actually creates a new one
            connection = [_rootContents getConnectionByName:[connection name] forConnectionType:[connection type]];
            if (selectedConnection) {
                [self selectConnection:connection];
            }
            if ([connection isManaged]) {
                [(NESManagedConnection *)connection updateConfiguration:^(NSMutableDictionary *config) {
                    if (config != nil) {
                        NSLog(@"ERROR: Pushed updates should just return nil (unless a conflict)!");
                    }
                }];
            }
        } else {
            [self addConnection:connection];
            [self selectConnection:connection];
        }

        [_rootContents saveConnections];
        
        return connection;
    } else {
        return nil;
    }
}

- (IBAction)addLocalForward:(NSMenuItem *)sender {

    [localForwardController initWithConnection:nil];
    [_prefsWindow beginSheet:[localForwardController window] completionHandler:^(NSModalResponse returnCode) {
        [self finishAddEditConnection:returnCode asType:NESConnectionLocalForward connectionName:nil withConfig:[localForwardController config]];
    }];
    
}

- (IBAction)addRemoteForward:(NSMenuItem *)sender {

    [remoteForwardController initWithConnection:nil];
    [_prefsWindow beginSheet:[remoteForwardController window] completionHandler:^(NSModalResponse returnCode) {
        [self finishAddEditConnection:returnCode asType:NESConnectionRemoteForward connectionName:nil withConfig:[remoteForwardController config]];
    }];
    
    
}

- (IBAction)addLocalProxy:(NSMenuItem *)sender {

    [proxyController initWithConnection:nil];
    [_prefsWindow beginSheet:[proxyController window] completionHandler:^(NSModalResponse returnCode) {
        [self finishAddEditConnection:returnCode asType:NESConnectionProxy connectionName:nil withConfig:[proxyController config]];
    }];
    
    
}

- (IBAction)addManagedConnection:(NSMenuItem *)sender {

    [managedConnectionController initWithConnection:nil];
    [_prefsWindow beginSheet:[managedConnectionController window] completionHandler:^(NSModalResponse returnCode) {
        [self finishAddEditConnection:returnCode asType:NESConnectionManaged connectionName:nil withConfig:[managedConnectionController config]];
    }];
    
}

- (void) clickOkay:(id) sender {
    NSLog(@"Clicked OKay!");
}


- (IBAction)minusClicked:(NSButton *)sender {
    
    // NESConnection *connection = (NESConnection *)[_outlineView itemAtRow:selectedRow];
    NESConnection *connection = selectedConnection;
    NESConnection *container = [connection parent];

    confirmSheet = [[NESConfirmationSheet alloc] init];
    [confirmSheet setConfirmationText:[NSString stringWithFormat:@"Are you sure you want to delete the %@ named \"%@\"?",[[NESConnection nameforType:[connection type]] lowercaseString] ,[connection name]]];
    [confirmSheet setParent:_prefsWindow];

    [_prefsWindow beginCriticalSheet:[confirmSheet window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            
            NSIndexSet *index = [_rootContents removeConnection:connection];
            
            [_outlineView beginUpdates];
            [_outlineView removeItemsAtIndexes:index inParent:container withAnimation:NSTableViewAnimationSlideLeft];
            [_outlineView endUpdates];
            [_outlineView reloadItem:container reloadChildren:YES];
            
            [_minusButton setEnabled:NO];
            [_actionButton setEnabled:NO];
            
            // Check to see if the container is empty, and remove it if necessary
            if ([[container children] count] == 0 ) {
                index = [_rootContents removeConnection:container];
                [_outlineView beginUpdates];
                [_outlineView removeItemsAtIndexes:index inParent:nil withAnimation:NSTableViewAnimationSlideLeft];
                [self showFilterBarIfNeeded];
                [_outlineView endUpdates];
                [self checkNeedsEmptyTable];
            }
            
            [_rootContents saveConnections];
            [self selectConnection:nil];
            
        }
    }];
    
}


- (void) doubleClickRow:(NSOutlineView *)sender {
    
    NESConnection *connection = (NESConnection *)[sender itemAtRow:[sender selectedRow]];
    
    if (([connection type]==NESConnectionContainer) || (connection == nil))
        [sender deselectRow:[sender selectedRow]];
    else {
        if ([connection status]&NESConnectionInvalid) {
            NSBeep();
        } else {
            [self selectConnection:connection];
            [self editConnection:connection];
        }
    }
    
}

- (void) editConnection:(NESConnection *)connection {

    
        // Edit the connection...
        NESConnectionWindowController *controller = nil;
        
        switch ([connection type]) {
            case NESConnectionLocalForward:
                controller = localForwardController;
                break;
            case NESConnectionRemoteForward:
                controller = remoteForwardController;
                break;
            case NESConnectionProxy:
            case NESConnectionManagedProxy:
                controller = proxyController;
                break;
            default:
                NSLog(@"ERROR: Trying to edit unknown connection type...");
                return;
                break;
        }
        
        [controller initWithConnection:connection];
        [_prefsWindow beginSheet:[controller window] completionHandler:^(NSModalResponse returnCode) {
            [self finishAddEditConnection:returnCode asType:[connection type] connectionName:[connection name] withConfig:[controller config]];
        }];

}

- (void) toggleConnection: (NSMenuItem *) menuItem {
    
    [[_prefsController controller] toggleConnection:menuItem];

}

- (void) duplicateConnection {
    
    //NESConnection *originalConnection = (NESConnection *)[_outlineView itemAtRow:selectedRow];
    NESConnection *originalConnection = selectedConnection;
    
    NSMutableDictionary *config = [[NSMutableDictionary alloc] initWithDictionary:[originalConnection connectionConfig]];
    [config removeObjectForKey:@"UUID"];
    
    NSString *dupName = [NSString stringWithFormat:@"%@ Copy",[originalConnection name]];
    int copy = 2;
    while ([_rootContents checkDuplicateName:dupName forConnectionType:[originalConnection type]]) {
        dupName = [NSString stringWithFormat:@"%@ Copy %d",[originalConnection name],copy++];
    }
    
    [config setObject:dupName forKey:@"name"];
    NESConnection *duplicate = [[NESConnection alloc] initWithName:dupName asType:[originalConnection type] andConfig:config];
    
    [self finishAddEditConnection:NSModalResponseOK asType:[duplicate type] connectionName:nil withConfig:config];

}

- (void) setMenuforConnection:(NESConnection *) connection {
    NSMenu *menu = [_actionButton menu];
    int index = 1;
    
    // Remove what we have now...
    while ([menu numberOfItems]>1) {
        [menu removeItemAtIndex:1];
    }
    
    NSMenuItem *stateDependentAction = [[NSMenuItem alloc] init];
    // Set state dependent item
    NSString *title;
    BOOL enabled = YES;
    switch ([connection status]&CONNECTION_STATE_MASK) {
        case NESConnectionIdle:
            if ([connection reconnecting]) {
                title = @"Cancel Retry";
            } else {
                title = @"Connect";                
            }
            break;
        case NESConnectionConnected:
        case NESConnectionConnecting:
            title = @"Disconnect";
            break;
        case NESConnectionError:
            if ([connection reconnecting]) {
                title = @"Cancel Retry";
            } else {
                title = @"Retry";
            }
            break;
        case NESConnectionInvalid:
            title = @"No Actions";
            enabled = NO;
            break;
        default:
            title = @"Unknown Connection State";
            enabled = NO;
            break;
    }
    [stateDependentAction setTitle:title];
    
    if (enabled) {
        [stateDependentAction setAction:@selector(toggleConnection:)];
        [stateDependentAction setRepresentedObject:connection];
        [stateDependentAction setTarget:self];
    }
    
    [stateDependentAction setEnabled:enabled];
    [menu insertItem:stateDependentAction atIndex:index++];
    [menu insertItem:[NSMenuItem separatorItem] atIndex:index++];
    
    NSMenuItem *action = [[NSMenuItem alloc] init];
    // Add the other actions...
    if (!([connection status]&NESConnectionInvalid)) {
        [action setTitle:@"Edit..."];
        [action setAction:@selector(editClicked:)];
//        [action setEnabled:YES];
        [action setTarget:self];
        [menu insertItem:action atIndex:index++];
    }
   

    action = [[NSMenuItem alloc] init];
    [action setTitle:@"Delete..."];
    [action setAction:@selector(minusClicked:)];
//    [action setEnabled:YES];
    [action setTarget:self];
    [menu insertItem:action atIndex:index++];

    if (![connection isManaged]) {
        action = [[NSMenuItem alloc] init];
        [action setTitle:@"Duplicate"];
        [action setAction:@selector(duplicateConnection)];
        [action setKeyEquivalent:@"d"];
//        [action setEnabled:YES];
        [action setTarget:self];
        [menu insertItem:action atIndex:index++];
    }
    
    
}

-(void) selectConnection:(NESConnection *) connection {
    
    if (connection) {
        BOOL enableButtons = ([connection status] != NESConnectionUpdatingConfig);
        
        [_minusButton setEnabled:enableButtons];
        [_actionButton setEnabled:enableButtons];
        [self setMenuforConnection:connection];
        [_outlineView scrollRowToVisible:[_outlineView rowForItem:connection]];
        [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_outlineView rowForItem:connection]] byExtendingSelection:NO];
    } else {
        [_outlineView deselectRow:[_outlineView selectedRow]];
        [_minusButton setEnabled:NO];
        [_actionButton setEnabled:NO];
    }

    selectedConnection = connection;
    
}

- (IBAction)tableClicked:(NSOutlineView *)sender {

    NESConnection *connection = (NESConnection *)[sender itemAtRow:[sender selectedRow]];

    if (([connection type]==NESConnectionContainer) || (connection == nil)) {
        [self selectConnection:nil];
    } else {
        [self selectConnection:connection];
    }
    
}

- (IBAction)editClicked:(NSButton *)sender {
    
    [self doubleClickRow:_outlineView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
        if ([keyPath isEqualToString:@"statusUpdated"]) {
            [_outlineView reloadData];
            [self selectConnection:selectedConnection];
            
        } else if ([keyPath isEqualToString:@"registered"]) {
            NSLog(@"Registration happened!");
            [_outlineView reloadData];
            [self selectConnection:selectedConnection];
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
}

@end
