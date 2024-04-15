//
//  NESConnectionWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/18/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESPopoverTextField.h"
#import "NESPopoverButton.h"
#import "NESConnectionViewController.h"
#import "NESSelectIdentityDelegate.h"
#import "NESSelectHostnameScriptDelegate.h"
#import "NESConnection.h"
#import "NESManagedConnection.h"
#import "nesPrefsWindowController.h"
#import "NESAppConfig.h"

#define DEFAULT_SSH_PATH @"~/.ssh"
#define DEFAULT_HOSTNAMESCRIPT_PATH @"~"

@interface NESConnectionWindowController : NSWindowController <NSTextFieldDelegate> {
    NESConnection *connection;
    NSArray *allFields;
    NSArray *requiredFields;
    BOOL disableValidation;
    BOOL isConnectionEdit;
    NESConfirmationSheet *confirmSheet;
    NESSelectIdentityDelegate *delegate;
    NESSelectHostnameScriptDelegate *selectScriptDelegate;
    NESAppConfig *appConfig;
}

@property (strong, nonatomic) IBOutlet NSMutableDictionary *config;
@property (strong) NSWindow *parentWindow;
@property NESConnectionViewController *connectionController;
@property (assign) NESConnectionType type;

- (IBAction)cancelWindow:(NSButton *)sender;
- (IBAction)addConnection:(NSButton *)sender;
- (IBAction)toggleUseCustomID:(id)sender;
- (IBAction)selectCustomID:(id)sender;
- (IBAction)selectHostnameScript:(id)sender;
- (IBAction)toggleReconnect:(id)sender;
- (IBAction)toggleUseHTTPPassword:(id)sender;
- (IBAction)toggleUseHTTPProxy:(id)sender;
- (IBAction)toggleUseScript:(id)sender;
- (void)initWithConnection:(NESConnection *)conn;
- (BOOL) checkConnectionName: (NSString *) name;
- (NSWindow *) myParent;

@property (strong) IBOutlet NESPopoverTextField *nameField;
@property (strong) IBOutlet NESPopoverTextField *sshServerField;
@property (strong) IBOutlet NESPopoverTextField *sshUsernameField;
@property (strong) IBOutlet NESPopoverTextField *sshPortField;
@property (strong) IBOutlet NSSecureTextField *sshPasswordField;

@property (strong) IBOutlet NESPopoverTextField *localAddressField;
@property (strong) IBOutlet NESPopoverTextField *localPortField;
@property (strong) IBOutlet NESPopoverTextField *remoteHostField;
@property (strong) IBOutlet NESPopoverTextField *bindDeviceField;
@property (strong) IBOutlet NESPopoverTextField *remoteHostPortField;
@property (strong) IBOutlet NSButton *autoConfigProxy;
@property (strong) IBOutlet NESPopoverButton *autoConfigHelp;
@property (strong) IBOutlet NSButton *useCustomIDBox;
@property (strong) IBOutlet NESPopoverTextField *sshIdentityField;
@property (strong) IBOutlet NSButton *useCustomSSHOptionsBox;
@property (strong) IBOutlet NSTextView *customSSHOptions;
@property (strong) IBOutlet NSButton *compressDataBox;
@property (strong) IBOutlet NSButton *startOnLaunchBox;
@property (strong) IBOutlet NSButton *includeInMenuBox;
@property (strong) IBOutlet NSButton *autoReconnectBox;

@property (strong) IBOutlet NSTextField *autoReconnectTime;
@property (strong) IBOutlet NSTextField *sshServerAliveCountMax;
@property (strong) IBOutlet NSTextField *sshServerAliveInterval;
@property (strong) IBOutlet NSButton *useScriptBox;
@property (strong) IBOutlet NESPopoverTextField *scriptField;
@property (strong) IBOutlet NSButton *useHTTPProxyBox;
@property (strong) IBOutlet NSButton *useHTTPPasswordBox;
@property (strong) IBOutlet NESPopoverTextField *httpProxyAddressField;
@property (strong) IBOutlet NESPopoverTextField *httpProxyPortField;
@property (strong) IBOutlet NSTextField *httpProxyUsernameLabel;
@property (strong) IBOutlet NESPopoverTextField *httpProxyUsernameField;
@property (strong) IBOutlet NSSecureTextField *httpProxyPasswordField;

@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet NSButton *addButton;
@property (strong) IBOutlet NSTabView *tabView;
@property (strong) IBOutlet NSButton *selectIDButton;
@property (strong) IBOutlet NSButton *selectScriptButton;

@property (strong) IBOutlet NSObjectController *objectController;


@end
