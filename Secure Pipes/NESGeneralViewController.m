//
//  NESGeneralViewController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/13/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//  Launch on login code:
//  Copyright (c) 2010 Justin Williams, Second Gear
//
//

#import "NESGeneralViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface NESGeneralViewController ()

@end

@implementation NESGeneralViewController

- (void)enableLoginItem:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
	if (item)
		CFRelease(item);
}

- (void)disableLoginItem:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (__bridge NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
			}
			// Docs for LSSharedFileListItemResolve say we're responsible
			// for releasing the CFURLRef that is returned
			if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
}


- (BOOL)loginItemExists:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath {
	BOOL found = NO;
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (__bridge NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
				found = YES;
				break;
			}
            // Docs for LSSharedFileListItemResolve say we're responsible
            // for releasing the CFURLRef that is returned
            if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
	
	return found;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.

    }
    return self;
}

- (void)setAppConfig:(NESAppConfig *)appConfig {
    _appConfig = appConfig;
    _config = [appConfig configDictionary];
}

- (void)awakeFromNib {
    
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if ([self loginItemExists:loginItems ForPath:appPath]) {
		[_loginLaunchCheckBox setState:NSOnState];
	}
	CFRelease(loginItems);

    CFStringRef hostname = SCDynamicStoreCopyComputerName ( nil, nil );
    if (hostname == nil) {
        defaultName = @"None";
    } else {
        defaultName = [NSString stringWithString:(__bridge NSString *)hostname];
        CFRelease(hostname);
    }
    [[_managedInstanceName cell] setPlaceholderString:defaultName];

    // For now...
    [_enableMangedConnectionsCheckBox setEnabled:NO];

    [_managedInstanceName setDelegate:self];
    [_managedInstanceName setEnabled:NO];
    [_managedStatusLight setHidden:YES];
    [_managedProgressIndicator setHidden:YES];
    [_registerButton setEnabled:NO];
    [_registerButton setHidden:NO];
    [_connectionManagerErrorMessage setHidden:YES];
    [self setManagedConnectionFields];
    NSLog(@"connectionManager thinks our name is: %@",[_connectionManager instanceName]);
    [_connectionManager addObserver:self forKeyPath:@"registered" options:NSKeyValueObservingOptionNew context:nil];
    [_connectionManager addObserver:self forKeyPath:@"connected" options:NSKeyValueObservingOptionNew context:nil];
    [_connectionManager addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
    
    if (!registrationSheet) {
        registrationSheet = [[NESManagedRegistrationSheet alloc] init];
    }
}

- (void) setManagedConnectionFields {
    
    if ([_enableMangedConnectionsCheckBox integerValue] == NSOffState) {
        [_connectionManager setReconnectOnDisconnect:NO];
        [_connectionManager stop];
        [_managedStatusLight setHidden:YES];
        [_managedProgressIndicator setHidden:YES];
        [_registerButton setEnabled:NO];
        [_registerButton setHidden:NO];
        [_managedInstanceName setEnabled:NO];
        [_connectionManagerErrorMessage setHidden:YES];
        
        // We remove the saved password and require reentry on disable
        NSString *keyChainName = [_appConfig configForKey:@"managedConnectionKeyChainName"];
        if ([NESKeychain keyChainItemExists:keyChainName withType:0]) {
            [NESKeychain removeKeyChainItem:keyChainName andType:0];
        }
        
    } else {
        [_managedInstanceName setEnabled:YES];
        [_connectionManager setReconnectOnDisconnect:YES];

        if (_connectionManager) {
            if ([_connectionManager isConnected]) {
                NSLog(@"Conection manager ready!");
            } else {
                [_connectionManager start];
            }
        }
    }
}

- (IBAction)checkAction:(NSButton *)sender {
    
    if (sender == _loginLaunchCheckBox) {
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        
        if ([_loginLaunchCheckBox integerValue] == NSOnState) {
			[self enableLoginItem:loginItems ForPath:appPath];
        } else {
			[self disableLoginItem:loginItems ForPath:appPath];
        }
    } else if (sender == _allowSavePasswordCheckBox) {
        if ([_allowSavePasswordCheckBox integerValue] == NSOffState) {
          [NESKeychain removeKeyChainItem:APP_NAME andType:0];
        }
    } else if (sender == _enableMangedConnectionsCheckBox) {
        [self setManagedConnectionFields];
        [self controlTextDidEndEditing:nil];
    }
    
    [_appConfig saveConfig];
    
}

- (IBAction)registerAction:(id)sender {
    
    NSString *account = ([_appConfig configForKey:@"managedConnectionAccount"] != nil)?[_appConfig configForKey:@"managedConnectionAccount"]:@"";
    
    [registrationSheet setParent:[[self view] window]];
    [[registrationSheet userNameField] setStringValue:account];
    [[registrationSheet passwordField] setStringValue:@""];
    [[registrationSheet verifyField] setStringValue:@""];
    [registrationSheet checkFields];
    [[registrationSheet window] makeFirstResponder:[registrationSheet userNameField]];
    [self controlTextDidEndEditing:nil];
    
    [[[self view] window] beginSheet:[registrationSheet window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            NSString *account = [[registrationSheet userNameField] stringValue];
            NSString *password = [[registrationSheet passwordField] stringValue];
            [_appConfig setConfigForKey:@"managedConnectionAccount" withValue:account];
            NSString *keyChainName = [_appConfig configForKey:@"managedConnectionKeyChainName"];
            // Remove the old keychain item if it exists
            if ([NESKeychain keyChainItemExists:keyChainName withType:0]) {
                [NESKeychain removeKeyChainItem:keyChainName andType:0];
            }
            [NESKeychain addKeyChainItem:keyChainName withUser:account andPassword:password andType:0];
            [_appConfig saveConfig];
            // Now we have all the registration info, let's update the UI.
            [self handleConnectStateChange:YES];
        }
    }];
    
}

- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    
    if ((commandSelector == @selector(insertTab:)) || (commandSelector == @selector(insertNewline:))) {
        [_managedInstanceName.window makeFirstResponder:nil];
        return YES;
    }
    
    return NO;
}

- (void) controlTextDidChange:(NSNotification *)obj {

}

- (void) controlTextDidEndEditing:(NSNotification *)obj {

    [_managedInstanceName.window makeFirstResponder:nil];
    if ([[_managedInstanceName stringValue] isEqualToString:@""]) {
        [_appConfig setConfigForKey:@"managedInstanceName" withValue:defaultName];
    }
    
    [_appConfig saveConfig];

}

- (void) handleRegistrationStateChange:(BOOL)registered {
    
    if (registered) {
        [_registerButton setHidden:YES];
        [_managedProgressIndicator stopAnimation:nil];
        [_managedProgressIndicator setHidden:YES];
        [_managedStatusLight setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [_managedStatusLight setHidden:NO];
        [_managedInstanceName setEnabled:NO];
        [_connectionManager run];
    } else {
        [_registerButton setEnabled:[_connectionManager connected]];
        [_registerButton setHidden:NO];
        [_managedStatusLight setHidden:YES];
        [_managedProgressIndicator setHidden:YES];
        [_managedInstanceName setEnabled:YES];
    }
    
}

- (void) registerClient {
    // Appears we can now register
    NSString *keyChainName = [_appConfig configForKey:@"managedConnectionKeyChainName"];
    NSMutableDictionary *credentials = [[NSMutableDictionary alloc] initWithDictionary:
                                        @{ @"username" : [_appConfig configForKey:@"managedConnectionAccount"] , @"password" : [NESKeychain getPassword:keyChainName andType:0]}];
    
    [_connectionManager registerClient:credentials];
    
}

- (void) handleConnectStateChange:(BOOL)connected {

    [_connectionManagerErrorMessage setHidden:YES];
    
    if (connected) {
        [_registerButton setHidden:NO];

        // See if we have an account and password
        NSString *keyChainName = [_appConfig configForKey:@"managedConnectionKeyChainName"];
        if (([_appConfig configForKey:@"managedConnectionAccount"])&&([NESKeychain keyChainItemExists:keyChainName withType:0])) {
            [_registerButton setEnabled:NO];
            [_registerButton setHidden:YES];
            [_managedStatusLight setHidden:YES];
            [_managedInstanceName setEnabled:NO];
            [_managedProgressIndicator setHidden:NO];
            [_managedProgressIndicator startAnimation:nil];
            [self registerClient];
        } else {
            [_registerButton setEnabled:YES];
        }

    } else {
        // Check to see if we were registered, then this means a disconnect
        if ([_connectionManager registered]) {
            [_managedStatusLight setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
            // We should schedule a re-try here...
            
        } else {
            [_registerButton setHidden:NO];
            [_registerButton setEnabled:NO];
            [_managedProgressIndicator setHidden:YES];
            [_managedStatusLight setHidden:YES];
        }
        
    }
    
    
}

- (void) handleConnectionManagerError:(BOOL)error {
    
    if (error) {
        NSString *errorMessage;
        switch ([_connectionManager errorCode]) {
            case NESconnectionManagerErrorAuthenticationFailed:
                errorMessage = @"Authentication failed. Please try registering again.";
                [self handleRegistrationStateChange:NO];
                break;
                
            default:
                errorMessage = @"An unknown error occurred.";
                break;
        }
        [_connectionManagerErrorMessage setStringValue:errorMessage];
        [_connectionManagerErrorMessage setHidden:NO];
        [_connectionManagerErrorMessage setToolTip:[_connectionManager errorMessage]];
    } else {
        [_connectionManagerErrorMessage setHidden:YES];
        [_connectionManagerErrorMessage setToolTip:@""];
    }
    
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    NSLog(@"Observer Called!");
    if ([keyPath isEqualToString:@"registered"]) {
        [self handleRegistrationStateChange:[_connectionManager registered]];
    }

    if ([keyPath isEqualToString:@"connected"]) {
        [self handleConnectStateChange:[_connectionManager connected]];
    }

    if ([keyPath isEqualToString:@"error"]) {
        [self handleConnectionManagerError:[_connectionManager error]];
    }

    
}

@end
