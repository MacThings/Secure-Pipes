//
//  NESConnectionWindowController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/18/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnectionWindowController.h"
#import "NESUser.h"
#import "NESGetScriptOutput.h"

@interface NESConnectionWindowController ()

@end

@implementation NESConnectionWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [self setConfig:[[NSMutableDictionary alloc] init]];
    }
    return self;
}

- (void) awakeFromNib {
    
    disableValidation = YES;
    [_addButton setEnabled:NO];
    
    // Disable these features for now
    [_useCustomIDBox setEnabled:YES];
    [_sshIdentityField setEnabled:NO];
    [_selectIDButton setEnabled:NO];
    [_compressDataBox setEnabled:YES];
    [_autoReconnectBox setEnabled:YES];
    
}

- (NSWindow *) myParent {
    NSArray *windows = [NSApp windows];
    
    for (id window in windows) {
        if (window == [self window])
            continue;
        if ([window attachedSheet] == [self window])
            return window;
    }
    
    return nil;
}

- (IBAction)selectHostnameScript:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    selectScriptDelegate = [[NESSelectHostnameScriptDelegate alloc] init];
    NSString *homeDir = DEFAULT_HOSTNAMESCRIPT_PATH;
    homeDir = [NSString stringWithFormat:@"file://%@",[homeDir stringByExpandingTildeInPath]];
    NSURL *homeURL = [NSURL URLWithString:homeDir];
    
    [panel setDelegate:selectScriptDelegate];
    [panel setDirectoryURL:homeURL];
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        
        if ([panel URL]) {
            [_config setObject:[[panel URL] path] forKey:@"hostnameScriptFile"];
        } else {
            [_config setObject:@"" forKey:@"hostnameScriptFile"];
        }
        
        [self controlTextDidEndEditing:[NSNotification notificationWithName:@"selectHostnameScript" object:_scriptField]];
    }];
    
}

- (void) validateHostnameScript:(id)sender {
    
    NESGetScriptOutput *testRun = [[NESGetScriptOutput alloc] initWithScript:[_config objectForKey:@"hostnameScriptFile"]];
    [testRun setConnection:connection];
    __block NSString *address, *error = nil;
    
    if (![testRun scriptExists]) {
        error = @"The specified script file no longer exists. Please select a new file.";
        goto validate;
    } else if (![testRun scriptIsExecutable]) {
        error = @"The specified script is not executable. Please change the permissions of the file or select a new one.";
        goto validate;;
    }
    
    // Looks like we have one and it's executable - let's try to run it.
    [testRun runWithCompletionHandler:^(NSString *output) {
        
        // Cut the output if illegal
        if ([output length] > _POSIX_HOST_NAME_MAX) {
            [output substringToIndex:(_POSIX_HOST_NAME_MAX-1)];
        }
        
        if (!([NESConnection isValidHost:output]||[NESConnection isValidIP:output])) {
            error = [NSString stringWithFormat:@"The specified script did not return a valid hostname or IP address. The returned value was:\n\n %@",output];
        }
        
        address = output;
    }];
    
validate:

    if (error) {
        [_scriptField setButtonPopoverMessage:error withType:NESErrorPopover];
        return;
    } else {
        [_sshServerField setStringValue:address];
        [_scriptField setButtonHidden:YES];
        [_config setObject:address forKey:@"sshServer"];
    }
    
}


- (IBAction)selectCustomID:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    delegate = [[NESSelectIdentityDelegate alloc] init];
    NSString *homeDir = DEFAULT_SSH_PATH;
    homeDir = [NSString stringWithFormat:@"file://%@",[homeDir stringByExpandingTildeInPath]];
    NSURL *homeURL = [NSURL URLWithString:homeDir];
    
    [panel setDelegate:delegate];
    [panel setDirectoryURL:homeURL];
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        
        if ([panel URL]) {
            [_config setObject:[[panel URL] path] forKey:@"sshIdentityFile"];
        } else {
            [_config setObject:@"" forKey:@"sshIdentityFile"];
        }
        [self validateSSHIdentityField:_sshIdentityField];
    }];
    
}

- (IBAction)toggleUseHTTPPassword:(id)sender {
    
    if (([_useHTTPPasswordBox integerValue] == YES) && ([_useHTTPProxyBox integerValue] == YES)) {
        [_httpProxyUsernameField setEnabled:YES];
        [_httpProxyPasswordField setEnabled:YES];
    } else {
        [_httpProxyUsernameField setEnabled:NO];    
        [_httpProxyPasswordField setEnabled:NO];
    }
    
}

- (IBAction)toggleUseHTTPProxy:(id)sender {
    
    if ([_useHTTPProxyBox integerValue] == YES) {
        [_httpProxyAddressField setEnabled:YES];
        [_httpProxyPortField setEnabled:YES];
        [_useHTTPPasswordBox setEnabled:YES];
    } else {
        [_httpProxyAddressField setEnabled:NO];
        [_httpProxyPortField setEnabled:NO];
        [_useHTTPPasswordBox setEnabled:NO];
        [self controlTextDidEndEditing:[NSNotification notificationWithName:@"toggleHTTPProxy" object:_httpProxyAddressField]];
        [self controlTextDidEndEditing:[NSNotification notificationWithName:@"toggleHTTPProxy" object:_httpProxyPortField]];
    }
    
    [self toggleUseHTTPPassword:nil];
    
}

- (IBAction)toggleUseScript:(id)sender {
    
    BOOL defaultServerFieldState = [connection isManaged]?[[connection configForKey:@"sshServerEnabled"] integerValue]:YES;
    
    if ([_useScriptBox integerValue] == YES) {
        [_scriptField setEnabled:YES];
        [_selectScriptButton setEnabled:YES];
        [_sshServerField setEnabled:NO];
        if ([_config  objectForKey:@"hostnameScriptFile"]) {
            [self controlTextDidEndEditing:[NSNotification notificationWithName:@"toggleHostnameScript" object:_scriptField]];
        }

    } else {
        if (![_scriptField isButtonHidden]) {
            [_scriptField setStringValue:@""];
            [_scriptField setButtonHidden:YES];
        }
        [_sshServerField setStringValue:[connection configForKey:@"sshServer"]?:@""];
        [_scriptField setEnabled:NO];
        [_selectScriptButton setEnabled:NO];
        [_sshServerField setEnabled:defaultServerFieldState];
    }
    
}

- (IBAction)toggleUseCustomID:(id)sender {
    
    if ([_useCustomIDBox integerValue] == YES) {
        [_sshIdentityField setEnabled:YES];
        [_selectIDButton setEnabled:YES];
        if (([[appConfig configForKey:@"showPasswordDialog"] boolValue] == YES) && (sender)) {
            confirmSheet = [[NESConfirmationSheet alloc] init];
            [confirmSheet setConfirmationText:[NSString stringWithFormat:@"When using an SSH key for authentication, only public key authentication is attempted. If your key is secured with a password, please enter it in the connection tab."]];
            [confirmSheet setParent:[self window]];
            [[confirmSheet cancelButton] setHidden:YES];
            [[confirmSheet showAgainBox] setHidden:NO];
            [[confirmSheet showAgainBox] setState:NSOffState];
            [[self window] beginCriticalSheet:[confirmSheet window] completionHandler:^(NSModalResponse returnCode) {
                if ([[confirmSheet showAgainBox] state] == NSOnState) {
                    // Update the appConfig here
                    [appConfig setConfigForKey:@"showPasswordDialog" withValue:@NO];
                    [appConfig saveConfig];
                }
            }];
        }
        
    } else {
        [_sshIdentityField setEnabled:NO];
        [_selectIDButton setEnabled:NO];
        [_addButton setEnabled:YES];
    }

    [self validateSSHIdentityField:_sshIdentityField];
    
}

- (IBAction)cancelWindow:(NSButton *)sender {
    
    disableValidation = YES;
    [[self myParent] endSheet:[self window] returnCode:NSModalResponseCancel];
    [_objectController removeObject:_config];
    connection = nil;
    
}

- (IBAction)addConnection:(NSButton *)sender {
    
    // If something is blank, put in the default value
    for (NSTextField *field in allFields) {
        if (([field stringValue] == nil)||([[field stringValue] isEqualToString:@""])) {
            [field setStringValue:[[field cell] placeholderString]];
            NSDictionary *bindingInfo = [field infoForBinding: NSValueBinding];
            [[bindingInfo valueForKey: NSObservedObjectKey] setValue: field.stringValue
                                                          forKeyPath: [bindingInfo valueForKey: NSObservedKeyPathKey]];
        }
    }

    [[self window] endEditingFor:nil];
    
    if (isConnectionEdit) {
        if ((([connection status]&CONNECTION_STATE_MASK) == NESConnectionConnected)||(([connection status]&CONNECTION_STATE_MASK) == NESConnectionConnecting)) {
            confirmSheet = [[NESConfirmationSheet alloc] init];
            [confirmSheet setConfirmationText:[NSString stringWithFormat:@"The connection \"%@\" is currently active. You must reconnect it for any network related changes to take effect.", [connection name]]];
            [confirmSheet setParent:[self window]];
            [[self window] beginCriticalSheet:[confirmSheet window] completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSModalResponseOK) {
                    [[self myParent] endSheet:[self window] returnCode:NSModalResponseOK];
                    connection = nil;
                }
            }];
            // Completion routine will pass status to perform add (if confirmed), otherwise sheet just disappears.
            return;
        }
    }
    
    
    [[self myParent] endSheet:[self window] returnCode:NSModalResponseOK];
    connection = nil;
    
    
}

- (BOOL) checkConnectionName: (NSString *) name {
    
    if ([[_connectionController rootContents] checkDuplicateName:name forConnectionType:_type])
        return ((connection != nil) && ([[connection name] isEqualToString:name]))?YES:NO;
    
    return YES;
}

- (void) validateLocalAddressField:(NESPopoverTextField *)field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if ((name == nil) || ([name isEqualToString:@""])) {
        error = @"If this field is left blank, \"localhost\" will be used for the default value. In this configuration, only local programs will have access to the forward via the loopback interface. If you would like to make the forward available to all hosts on your network, enter \"*\" to bind to all interfaces. Or, if you would like to bind to just one of this machine's specific IP addresses, you can enter it (or it\'s associated hostname).";
        [field setButtonPopoverMessage:error withType:NESWarningPopover];
        return;
    } else if ((!([NESConnection isValidHost:name]||[NESConnection isValidIP:name]))&&(![name isEqualToString:@"*"])) {
        error = [NSString stringWithFormat:@"\"%@\" does not appear to be a valid IP or hostname. This value should be the hostname or IP address of an interface on this host. If you want only local programs to have access to the forward via the loopback interface, use \"localhost\" or 127.0.0.1 for the address (or leave the field blank). If you want all hosts on your network to have access to the forward, use \"*\".",name];
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
        return;
    }
    
    [field setButtonHidden:YES];
}

- (void) validateGeneralPortField:(NESPopoverTextField *)field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
   
    if (![field isEnabled]) {
        [field setButtonHidden:YES];
        return;
    }
    
    if ((name == nil) || ([name isEqualToString:@""])) {
        error = @"The default port for this field has been chosen randomly. Please confirm it is the desired port and modify if necessary.";
        if (field != _sshPortField)
            [field setButtonPopoverMessage:error withType:NESWarningPopover];
        return;
    } else if (![NESConnection isValidPort:name]) {
        error = [NSString stringWithFormat:@"\"%@\" is not a valid port number. Please enter a number between 1 and 65535.",name];
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
        return;
    } else if (([name integerValue]<1024)&&(field == _localPortField)) {
        if ([[NESUser currentUser] isMemberOfAdminGroup]) {
            error = [NSString stringWithFormat:@"Please note binding to ports less than 1024 requires administrative privileges. You will be prompted for your password when the connection starts. If the account \"%@\" loses administrative privileges, the connection will fail.",NSFullUserName()];
            [field setButtonPopoverMessage:error withType:NESWarningPopover];
        } else {
            error = [NSString stringWithFormat:@"The current account \"%@\" does not have the administrative privileges required to bind to ports less than 1024. Please make this account an administrator or log in as a user with administrative privileges.",NSFullUserName()];
            [field setButtonPopoverMessage:error withType:NESErrorPopover];
        }
        
        return;
    }
    
    [field setButtonHidden:YES];
    
}



- (void) validateRemoteHostField:(NESPopoverTextField *) field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if ((name == nil) || ([name isEqualToString:@""]))
        error = @"The remote host host name or IP address to forward the connection to is required. Please enter a valid host name or IP address. In some cases this may be the SSH server itself, in which case \"localhost\" can be specified. In other cases it may be a server only accessible to the SSH server via one of it\'s networks.";
    else if (!([NESConnection isValidHost:name]||[NESConnection isValidIP:name])) {
        error = [NSString stringWithFormat:@"\"%@\" does not appear to be a valid IP or hostname. Please check your entry to make sure it is well-formed and does not contain any illegal characters.",name];
    }
    
    if (error != nil) {
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
    } else {
        if (![field isButtonHidden]) {
            [field setButtonHidden:YES];
        }
    }
    
}

- (void) validateProxyAddressField:(NESPopoverTextField *) field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if ((name == nil) || ([name isEqualToString:@""]))
        error = @"The proxy server host name or IP address is required. Please enter a valid host name or IP address.";
    else if (!([NESConnection isValidHost:name]||[NESConnection isValidIP:name])) {
        error = [NSString stringWithFormat:@"\"%@\" does not appear to be a valid IP or hostname. Please check your entry to make sure it is well-formed and does not contain any illegal characters.",name];
    }
    
    if ((error != nil) && ([_useHTTPProxyBox integerValue] == YES)) {
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
    } else {
        if (![field isButtonHidden]) {
            [field setButtonHidden:YES];
        }
    }
    
}



- (void) validateSSHAddressField:(NESPopoverTextField *) field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if (((name == nil) || ([name isEqualToString:@""])) && ([_useScriptBox integerValue] != YES))
        error = @"The remote SSH server host name or IP address is required. Please enter a valid host name or IP address.";
    else if (!([NESConnection isValidHost:name]||[NESConnection isValidIP:name])) {
        error = [NSString stringWithFormat:@"\"%@\" does not appear to be a valid IP or hostname. Please check your entry to make sure it is well-formed and does not contain any illegal characters.",name];
    }
    
    if (error != nil) {
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
    } else {
        if (![field isButtonHidden]) {
            [field setButtonHidden:YES];
        }
    }
    
}

- (void) validateUsernameField:(NESPopoverTextField *) field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if ((name == nil) || ([name isEqualToString:@""]))
        error = @"An SSH username must be supplied for the connection.";
    
    if (error != nil) {
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
    } else {
        if (![field isButtonHidden]) {
            [field setButtonHidden:YES];
        }
    }
    
}

- (IBAction)toggleReconnect:(id)sender {
    [self validateNumberField:_autoReconnectTime withBinding:@"reconnectInterval"];
}

- (void) validateNumberField:(NSTextField *) field withBinding: binding {
    
    NSString *defaultValue = [[[NESConnection defaultConfigForType:[connection type]] valueForKey:binding] stringValue];
    NSString *origValue = [connection configForKey:binding]==nil?defaultValue:[[connection configForKey:binding] stringValue];
    NSString *value = [field stringValue];
    
    if ((![value length]) || ([[value stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] length]>0)) {
        [field setStringValue:origValue];
    }
    
}


- (void) validateSSHIdentityField:(NESPopoverTextField *) field {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fieldValue = [field stringValue]==nil?@"":[field stringValue];
    NSString *error = nil;
    BOOL isDir;
    NSString *supportPath = [fieldValue stringByExpandingTildeInPath];
    
    if ([_useCustomIDBox integerValue] == NO) {
        goto skip_check;
    }
    
    if ([fieldValue isEqualToString:@""]) {
            error = @"Click the button to the right to specify the location of a valid SSH identitfy file.";
    } else if (![fileManager fileExistsAtPath:supportPath isDirectory:&isDir]) {
        error = @"Specified file no longer exists. Please choose another file using the button to the right.";
    }

    skip_check:
    
    if (error != nil) {
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
        [_addButton setEnabled:NO];
    } else {
        [_addButton setEnabled:YES];
        if (![field isButtonHidden]) {
            [field setButtonHidden:YES];
        }
    }
    
}

- (void) validateNameField:(NESPopoverTextField *) field {
    
    NSString *error = nil;
    NSString *name = [field stringValue];
    
    if ((name == nil) || ([name isEqualToString:@""]))
        error = @"A name must be supplied for the connection. Please enter a descriptive label to identify the connection such as \"Authentication Server\", \"Cloud Intranet\", etc.";
    else if (![self checkConnectionName:name]) {
        error = [NSString stringWithFormat:@"A local forward connection with the name \"%@\" already exists. Please select another name.",name];
    }
    
    if (error != nil) {
        if ([field isButtonHidden]) {
            // NSBeep();
        }
        [field setButtonPopoverMessage:error withType:NESErrorPopover];
    } else {
        if (![field isButtonHidden]) {
            [field setButtonHidden:YES];
        }
    }
    
}

// The next two methods are the way we are notified to do validation (either the value changed or we left a field)

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    
    NESPopoverTextField *field = [notification object];
    
    if (disableValidation)
        return;
    
    if (field == _nameField) {
        [self validateNameField:field];
    } else if (field == _sshServerField) {
        [self validateSSHAddressField:field];
    } else if (field == _localAddressField) {
        [self validateLocalAddressField:field];
    } else if (field == _remoteHostField) {
        [self validateRemoteHostField:field];
    } else if ((field == _sshPortField)||(field == _localPortField)||(field == _remoteHostPortField)) {
        [self validateGeneralPortField: field];
    } else if (field == _sshUsernameField) {
        [self validateUsernameField:field];
    } else if (field == _bindDevice) {
        [self validateUsernameField:field];
    } else if (field == _autoReconnectTime) {
        [self validateNumberField:field withBinding:@"reconnectInterval"];
    } else if (field == _sshServerAliveCountMax) {
        [self validateNumberField:field withBinding:@"sshServerAliveCountMax"];
    } else if (field == _sshServerAliveInterval) {
        [self validateNumberField:field withBinding:@"sshServerAliveInterval"];
    } else if (field == _httpProxyAddressField) {
        [self validateProxyAddressField:field];
    } else if (field == _httpProxyPortField) {
        [self validateGeneralPortField:field];
    } else if (field == _scriptField) {
        [self validateHostnameScript:field];
        [self validateSSHAddressField:_sshServerField];
    } else {
        //NSLog(@"WARNING: No verifier for this field...");
    }
    
    BOOL activateButton = YES;
    // Check to make sure we have all the values we need
    for (id field in requiredFields) {
        if (([field stringValue] == nil)||([[field stringValue] isEqualToString:@""])) {
            activateButton = NO;
            break;
        }
    }
    
    if (!activateButton) {
        [_addButton setEnabled:activateButton];
        return;
    }
    
    // Check if any errors
    for (id field in allFields) {
        if (([[field className] isEqualToString: @"NESPopoverTextField"])&&(![field isButtonHidden])&&([field popoverType] == NESErrorPopover)) {
            activateButton = NO;
            break;
        }
    }
    
    [_addButton setEnabled:activateButton];
    
}

-(void) controlTextDidChange:(NSNotification *)notification {
    
    NESPopoverTextField *field = [notification object];

    if (field != _scriptField) {
        [self controlTextDidEndEditing:notification];
    }
    
}

- (void) initWithConnection:(NESConnection *)conn {
    
    if (conn != nil) {
        // This is an edit
        connection = conn;
        _config = [[NSMutableDictionary alloc] initWithDictionary:[connection connectionConfig]];
        [_addButton setTitle:@"Apply"];
        [_addButton setEnabled:YES];
        
        isConnectionEdit = YES; // There is probably some way we can sniff this out, but let's just make it clear
    } else {
        // This is an add
        //_config = [[NSMutableDictionary alloc] init];
        _config = [NESConnection defaultConfigForType:_type];
        connection = nil;
        [_addButton setTitle:@"Add"];
        [_addButton setEnabled:NO];
        isConnectionEdit = NO;
    }
    
    disableValidation = YES;
    [_objectController setContent:_config];
    [[self window] makeFirstResponder:_nameField];
    disableValidation = NO;
    
    for (id field in allFields) {
        if ([[field className] isEqualToString: @"NESPopoverTextField"] ) {
            [field setButtonHidden:YES];
        }
    }

    [self toggleUseCustomID:nil];
    [self toggleUseHTTPProxy:nil];
    [self toggleUseHTTPPassword:nil];
    [self toggleUseScript:nil];
    
    [_tabView selectFirstTabViewItem:nil];
    appConfig = [[_connectionController prefsController] appConfig];
    [_allowManagement setEnabled:[[appConfig configForKey:@"enableManagedConnections"] boolValue]];
    [_config setObject:[appConfig configForKey:@"instanceUUID"] forKey:@"lastRevisionBy"];
    
    
}


@end
