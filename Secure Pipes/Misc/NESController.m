//
//  NESController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/3/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESController.h"
#import "NESUser.h"

static const int NESConnectionRestartDelay = 30;

@implementation NESController

-(id) initWithDelegate: (NESAppDelegate *)delegate {
    self = [super init];
    
    if (self) {
        _connections = [[NESConnections alloc] init];
        [_connections loadConnections];
        [_connections addObserver:self forKeyPath:@"configUpdated" options:NSKeyValueObservingOptionNew context:nil];
        [_connections addObserver:self forKeyPath:@"statusHasUpdate" options:NSKeyValueObservingOptionNew context:nil];
        
        _appDelegate = delegate;
        [self buildMenu];
        
        // Setup the icon controller
        _iconController = [[NESMenuIconController alloc] init];
        [_iconController setStatusBarItem:[_appDelegate statusItem]];
        [self darkModeChanged:nil];
        [_iconController setMenuForConnections:_connections];

        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeChanged:) name:@"AppleInterfaceThemeChangedNotification" object:nil];        
        
        _appConfig = [[NESAppConfig alloc] init];
        [_appConfig loadConfig];
        
        _connectionManager = [[NESConnectionManager alloc] initWithConnections:_connections];
        [_connectionManager setAppConfig:_appConfig];
        if ([[_appConfig configForKey:@"enableManagedConnections"] boolValue]) {
            NSLog(@"Managed connections enabled!");
            [_connectionManager setReconnectOnDisconnect:YES];
            [_connectionManager start];
        }

        
        [self fileSleepWakeNotifications];
        
        // Start the connections that should start on launch... 
        for (NESConnection *conn in [_connections getStartOnLaunchConnections]) {
            [self startConnection:conn];
        }
        
    }
    
    return self;
}

-(void) darkModeChanged:(NSNotification *)notif {

    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = [dict objectForKey:@"AppleInterfaceStyle"];
    BOOL darkMode = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
    NSLog(@"Dark mode: %hhd",darkMode);

    [_iconController setDarkMode:darkMode];
    [_iconController setMenuForConnections:_connections];
    
}

- (BOOL) confirmHostKey:(NESConnection *) connection withKey:(NSString *)key andReplace:(BOOL)replace {
    
    confirmationDialog = [[NESConfirmationDialogWindowController alloc] init];
    if (!replace) {
        NSString *confirmationText = NSLocalizedString(@"The authenticity of this host cannot be confirmed. Please confirm the host key fingerprint below is valid:", nil);
        [confirmationDialog setConfirmationText:confirmationText];

    } else {
        NSString *warningText = NSLocalizedString(@"Warning: The host key fingerprint of this server has changed. Please confirm the new host key fingerprint below is valid:", nil);
        [confirmationDialog setConfirmationText:warningText];

    }
    
    [confirmationDialog setSubText:key];
    
    [NSApp activateIgnoringOtherApps:YES];
    NSModalResponse result = [NSApp runModalForWindow:[confirmationDialog window]];
    [[confirmationDialog window] close];
    
    return result;
}

- (BOOL) authenticateConnection:(NESConnection *) connection {
    
    passwordDialog = [[NESAdminPasswordDialogWindowController alloc] init];
    [passwordDialog setConnection:connection];
    [passwordDialog setNameFieldText:NSFullUserName()];
    [[passwordDialog nameField] setEnabled:NO];
    if ([[_appConfig configForKey:@"allowSavePassword"] integerValue] == YES) {
        if ([connection needsSavedAdministratorPasswd]) {
            [passwordDialog enableSavePassword:NO];
            [[passwordDialog saveCheckBox] setState:YES];
        } else {
            [passwordDialog enableSavePassword:YES];
        }
    } else {
        [passwordDialog enableSavePassword:NO];
    }
    [[passwordDialog window] makeFirstResponder:[passwordDialog passwordField]];
    [NSApp activateIgnoringOtherApps:YES];
    NSModalResponse result = [NSApp runModalForWindow:[passwordDialog window]];
    
    [[passwordDialog window] close];
    
    if (result == NSModalResponseOK) {
        [[connection connectionProcess] setPasswd:[passwordDialog password]];
    }
    
    return (result==NSModalResponseOK);
    
}

- (void) startConnection:(NESConnection *)connection {

    if ([connection needsAdministratorRights]) {
        // Prompt if the authentication has failed or if no Keychain item exists
        if (([connection status]&NESConnectionAuthenticationFailed) || (![NESKeychain keyChainItemExists:APP_NAME withType:0])) {
            if (![self authenticateConnection:connection]) {
                return;
            }
        } else {
            [[connection connectionProcess] setPasswd:[NESKeychain getPassword:APP_NAME andType:0]];
        }
    }
    [connection startConnection];
    
}

- (void) toggleConnection: (NSMenuItem *) menuItem {
    NESConnection *connection = [menuItem representedObject];
    
    switch ([connection status]&CONNECTION_STATE_MASK) {
        case NESConnectionIdle:
        case NESConnectionAuthenticationFailed:
        case NESConnectionError:
            if ([connection reconnecting]) {
                [[connection reconnectTimer] invalidate];
                [connection stopConnection];
                [connection setReconnecting:NO];
                [connection queueStatusUpdate:NESConnectionIdle withData:@""];
                return;
            }
            
            [self startConnection:connection];
            
            break;
        case NESConnectionConnected:
        case NESConnectionConnecting:
            [connection stopConnection];
        default:
            break;
    }
        
}

- (NSMenuItem *) menuForContainer:(NESConnection *) container {
    NSMenuItem *newItem = [[NSMenuItem alloc] init];
    
    [newItem setTitle:[container name]];
    [newItem setEnabled:NO];
    
    return newItem;
}

- (NSMenuItem *) getMenuForConnection:(NESConnection *) connection {
    NSMenu *menu = [_appDelegate menu];
    
    for (id menuItem in [menu itemArray]) {
        if ([menuItem representedObject] == connection) {
            return menuItem;
        }
    }
    
    return nil;
}

- (NSString *) menuName:(NESConnection *)connection forStatus:(NESConnectionStatus)status {
    
    switch (status&CONNECTION_STATE_MASK) {
            case NESConnectionIdle:
            if ([connection reconnecting]) {
                return [NSString stringWithFormat:NSLocalizedString(@"Cancel %@", nil), [connection name]];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"Connect %@", nil), [connection name]];
            }
            break;
            case NESConnectionConnected:
            case NESConnectionConnecting:
            return [NSString stringWithFormat:NSLocalizedString(@"Disconnect %@", nil), [connection name]];
            case NESConnectionAuthenticationFailed:
            case NESConnectionError:
            if ([connection reconnecting]) {
                return [NSString stringWithFormat:NSLocalizedString(@"Cancel %@", nil), [connection name]];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"Retry %@", nil), [connection name]];
            }
        default:
            return @"No Action Available";
            break;
    }
    
}

- (NSMenuItem *) newMenuForConnection:(NESConnection *) connection {
    NSMenuItem *newItem = [[NSMenuItem alloc] init];
    
    // Looks a little cleaner without the indentation.
    //[newItem setIndentationLevel:1];
    [newItem setImage:[NESConnection imageForStatus:[connection status]]];
    [newItem setEnabled:YES];
    [newItem setTitle:[self menuName:connection forStatus:[connection status]]];
    [newItem setAction:@selector(toggleConnection:)];
    [newItem setTarget:self];
    [newItem setRepresentedObject:connection];
    
    return newItem;
}

+ (NSMutableDictionary *) dictionaryFromTXTRecord:(NSString *)record {
    
    NSRange nextEqual = [record rangeOfString:@"="];
    if (nextEqual.location != NSNotFound ) {
        NSRange nextSpace = [record rangeOfString:@" " options:0 range:NSMakeRange(nextEqual.location, record.length-nextEqual.location)];
        NSString *remainder = [record substringWithRange:NSMakeRange(nextSpace.location+1,record.length-nextSpace.location-1)];
        NSString *keyValue = [record substringWithRange:NSMakeRange(0, nextSpace.location)];
        NSMutableDictionary *dict = [NESController dictionaryFromTXTRecord:remainder];
        
        keyValue = [keyValue stringByReplacingOccurrencesOfString:@"[space]" withString:@" "];
        NSArray *tuplet = [keyValue componentsSeparatedByString:@"="];
        [dict setValue:[tuplet objectAtIndex:1] forKey:[tuplet objectAtIndex:0]];
        
        return dict;
    } else {
        return [[NSMutableDictionary alloc] init];
    }
}

- (void) handleConnectionStatusChange:(NESConnection *) connection withUpdate:(NSDictionary *) update {

    NESConnectionStatus oldStatus = [connection status];
    NESConnectionStatus newStatus = [(NSString *)[update objectForKey:@"status"] integerValue];
    
    if (newStatus != NESConnectionInfoReceived) {
        [connection setStatusWithUpdate:update];
    }
    
    if (newStatus&NESConnectionUnknownKey) {
        
        [connection setStatus:NESConnectionIdle];
        
        NSString *keyString = [update objectForKey:@"args"];
        BOOL confirmed = [self confirmHostKey:connection withKey:keyString andReplace:NO];
        if (confirmed) {
            [connection setConfigForKey:@"hostKeyFingerPrint" value:keyString];
            [connection startConnection];
            return;
        } else {
            [connection setStatus:NESConnectionError];
            NSString *message = NSLocalizedString(@"The authenticity of the host key fingerprint was not confirmed.", nil);
            [connection setStatusForKey:@"message" value:message];

        }
        
    } else if (newStatus&NESConnectionKeyChanged) {
        
        [connection setStatus:NESConnectionIdle];
        
        NSString *keyString = [update objectForKey:@"args"];
        BOOL confirmed = [self confirmHostKey:connection withKey:keyString andReplace:YES];
        if (confirmed) {
            [NESConnection removeKnownHostFile:connection];
            [connection setConfigForKey:@"hostKeyFingerPrint" value:keyString];
            [connection startConnection];
            return;
        } else {
            [connection setStatus:NESConnectionError];
            NSString *message = NSLocalizedString(@"The host key of the server changed and the new key was not confirmed.", nil);
            [connection setStatusForKey:@"message" value:message];

        }
        
    } else if ((newStatus&NESConnectionError)&&((oldStatus&NESConnectionConnected)||oldStatus&NESConnectionConnecting)) {
        [connection stopBonjourService];
        [self scheduleReconnectAsNeeded:connection];
    } else if (newStatus&NESConnectionAuthenticationFailed) {
        NSString *errorMessage = [update objectForKey:@"data"];
        [connection setStatus:NESConnectionError];
        if (errorMessage == nil) {
            errorMessage = NSLocalizedString(@"Authentication with the SSH server failed. Please check the password, SSH server configuration, or identity used.", nil);
        }
        [connection setStatusForKey:@"message" value:errorMessage];
    } else if (!(oldStatus&NESConnectionConnected) && (newStatus&NESConnectionConnected)) {
        // Do anything we need to do now that we know we're connected. 
        NSLog(@"Now Connected!");
        [connection publishBonjourService];
    } else if (newStatus&NESConnectionInfoReceived) {
        // TODO: This is kind of a hack. We need to handle info messages better
        if ([[update objectForKey:@"data"] hasPrefix:@"home-sharing"]) {
            // Check the data
            NSString *record = [[update objectForKey:@"args"] stringByReplacingOccurrencesOfString:@"\\ " withString:@"[space]"];
            record = [record stringByAppendingString:@" "];
            NSMutableDictionary *homeSharingConfig = [NESController dictionaryFromTXTRecord:record];
            [connection resetBonjourTXTData:homeSharingConfig withSubType:[homeSharingConfig objectForKey:@"hG"]];
        }
    } else {
        NSLog(@"UNKNOWN STATE TRANSITION: %ld -> %ld",oldStatus&CONNECTION_STATE_MASK,newStatus&CONNECTION_STATE_MASK);
        NSLog(@"Update: %@",update);
    }
    
    [self updateMenuForStatus:connection];
    [_connections setStatusUpdated:YES];
    
    if ([[_appConfig configForKey:@"useNotificationCenter"] integerValue] == YES) {
        [self sendStatusChangeNotification:connection withOldStatus:oldStatus];
    }
    
}

- (void) handleConnectionSyncStatusChange:(NESConnection *) connection withUpdate:(NSDictionary *) update {

    //NESConnectionStatus oldSyncStatus = [connection status]&~CONNECTION_STATE_MASK;
    NESConnectionStatus newSyncStatus = [(NSString *)[update objectForKey:@"status"] integerValue]&~CONNECTION_STATE_MASK;

    NSLog(@"Current status of %@: %@",[connection name],[connection connectionStatus]);
    NSLog(@"Status update: %@",update);
    
    if (newSyncStatus&NESConnectionUpdatingConfig) {
        [connection setStatusWithUpdate:update];
    } else if (newSyncStatus&NESConnectionSyncFailure) {
        [connection setStatusWithUpdate:update];
    } else if ((newSyncStatus&NESConnectionNetworkConfigChanged)&&([[connection connectionProcess] isRunning])) {
        // Restart connection
        [connection stopConnectionSynchronous];
        [self startConnection:connection];
    } else if (newSyncStatus&NESConnectionConfigInvalidated) {
        if ([connection status]&(NESConnectionConnected|NESConnectionConnecting)) {
            [connection stopConnectionSynchronous];
            if ([connection reconnectTimer]) {
                [[connection reconnectTimer] invalidate];
            }
        }
        [connection setStatus:NESConnectionInvalid];
        [self buildMenu];
        
    } else if (newSyncStatus&NESConnectionConfigRevalidated) {
        [connection setStatus:NESConnectionIdle];
        [self buildMenu];
    } else {
        [connection setStatus:NESConnectionSyncOk];
    }

    [self updateMenuForStatus:connection];
    [_connections setStatusUpdated:YES];
    
}

- (void) updateForStatusChange:(NESConnection *) connection {
    NSDictionary *update = [connection dequeueStatusUpdate];
    NESConnectionStatus newStatus = [(NSString *)[update objectForKey:@"status"] integerValue];
    
    if (newStatus&CONNECTION_STATE_MASK) {
        [self handleConnectionStatusChange:connection withUpdate:update];
    } else {
        [self handleConnectionSyncStatusChange:connection withUpdate:update];
    }
    
    
}

- (void) sendStatusChangeNotification:(NESConnection *) connection withOldStatus:(NESConnectionStatus)oldStatus {
    
    // We'll just ignore INFO messages for now...
    if ([connection status] == oldStatus)
        return;

    NSUserNotification *notification = [[NSUserNotification alloc] init];
    NSString *title, *subtitle, *type;
    
    switch ([connection type]) {
        case NESConnectionLocalForward:
            type = @"local forward";
            break;
        case NESConnectionRemoteForward:
            type = @"remote forward";
            break;
        case NESConnectionProxy:
        case NESConnectionManagedProxy:
            type = @"proxy";
            break;
        default:
            type = @"unknown connection";
            break;
    }
    
    title = [NSString stringWithFormat:@"\"%@\" Status Update",[connection name]];
    switch ([connection status]&CONNECTION_STATE_MASK) {
        case NESConnectionConnected:
            title = NSLocalizedString(@"Secure Connection Successful", nil);
            subtitle = [NSString stringWithFormat:NSLocalizedString(@"The %@ connection \"%@\" connected successfully.", nil), type, [connection name]];

            break;
        case NESConnectionAuthenticationFailed:
            title = NSLocalizedString(@"Secure Connection Failure", nil);
            subtitle = [NSString stringWithFormat:NSLocalizedString(@"The %@ connection \"%@\" failed to connect (Permission denied).", nil),type,[connection name]];
            break;
        case NESConnectionError:
            title = NSLocalizedString(@"Secure Connection Failure", nil);
            if (oldStatus&NESConnectionConnected) {
                subtitle = [NSString stringWithFormat:NSLocalizedString(@"The %@ connection \"%@\" unexpectedly disconnected.", nil),type,[connection name]];
            } else {
                subtitle = [NSString stringWithFormat:NSLocalizedString(@"The %@ connection \"%@\" failed to connect.", nil),type,[connection name]];
            }
            break;
        case NESConnectionIdle:
            title = NSLocalizedString(@"Secure Connection Disconnected", nil);
            subtitle = [NSString stringWithFormat:NSLocalizedString(@"The %@ connection \"%@\" was disconnected.", nil),type,[connection name]];
            break;
        case NESConnectionConnecting:
            return;
        default:
            return;
            break;
    }
    [notification setTitle:title];
    [notification setInformativeText:subtitle];
    [notification setHasActionButton:NO];
    [notification setHasReplyButton:NO];
        
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
}

- (void) updateMenuForStatus:(NESConnection *) connection {
    NSMenuItem *menuItem = [self getMenuForConnection:connection];

    [menuItem setImage:[NESConnection imageForStatus:[connection status]]];
    [menuItem setTitle:[self menuName:connection forStatus:[connection status]]];
    [_iconController setMenuForConnections:_connections];
}

- (BOOL) includeConnectionInMenu:(NESConnection *)connection {
    
    if (![connection isManaged]) {
        return [[connection configForKey:@"includeInMenu"] boolValue];
    } else {
        return !(([connection status]&CONNECTION_STATE_MASK) == NESConnectionInvalid);
    }
    
}

- (void) buildMenu {
    
    NSMenu *menu = [_appDelegate menu];
    [menu setAutoenablesItems:NO];
    NSInteger indexOfEnd = [menu indexOfItemWithTarget:_appDelegate andAction:NSSelectorFromString(@"showPrefsWindow:")];
    
    // Remove all items above preferences and rebuild (I know this is inefficient, but it's easy and less code/stuff to pass around
    for (int ctr=0;ctr<indexOfEnd;ctr++)
        [menu removeItemAtIndex:0];
    
    
    int indx = 0;
    for (id container in [_connections children]) {
        // Build from the top down...
        [menu insertItem:[self menuForContainer:container] atIndex:indx++];
        int containerIndex = indx;
        for (id connection in [container children]) {
            if ([self includeConnectionInMenu:connection])
                [menu insertItem:[self newMenuForConnection:connection] atIndex:indx++];
        }
        
        // Remove the container if nothing in there
        if (indx == containerIndex) {
            [menu removeItemAtIndex:--indx];
        } else {
            [menu insertItem:[NSMenuItem separatorItem] atIndex:indx++];
            
        }
    }
    
}

-(void) fastStopAllConnections {
    [_connections fastStopActiveConnections];
}

-(void) stopAllConnections {
    [_connections stopActiveConnections];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (object == _connections) {
        if ([keyPath isEqualToString:@"configUpdated"]) {
            [self buildMenu];
            // Not the best solution, but handles edge case of deleting an active connection
            [_iconController setMenuForConnections:_connections];
        } else if ([keyPath isEqualToString:@"statusHasUpdate"]) {
            [self updateForStatusChange:[_connections getHasStatusUpdateConnection]];
        }
    }

}


- (void) receiveSleepNote: (NSNotification*) note
{
    if ([[_appConfig configForKey:@"relaunchOnWake"] boolValue] == YES) {
        [_connections stopActiveConnections];
    }

}

- (void) receiveWakeNote: (NSNotification*) note
{
    if ([[_appConfig configForKey:@"relaunchOnWake"] boolValue] == YES) {
        [_connections restartStoppedConnections];
    }
}

- (void) fileSleepWakeNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];


}

- (void) scheduleReconnectAsNeeded:(NESConnection *) connection {
    
    if ([[connection configForKey:@"autoReconnect"] boolValue]) {
        int delay = [connection configForKey:@"reconnectInterval"]==nil?NESConnectionRestartDelay:[[connection configForKey:@"reconnectInterval"] intValue];
        NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(reconnectTimerExpired:) userInfo:connection repeats:NO];
        [connection setReconnecting:YES];
        [connection setReconnectTimer:timer];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        NSLog(@"Reconnect scheduled in %d seconds.",delay);
    } 
    
}

- (void) reconnectTimerExpired:(NSTimer *) timer {
    NESConnection *connection = [timer userInfo];
    NSLog(@"Timer expired, reconnecting: %@",[connection name]);
    if ([[connection connectionProcess] isRunning]) {
        NSLog(@"ERROR: CONNECTION STILL RUNNING AFTER ERROR: Forcing it to quit.");
        [[connection connectionProcess] hardStopConnection];
        [self scheduleReconnectAsNeeded:connection];
        return;
    }
    [connection startConnection];
    
}

@end
