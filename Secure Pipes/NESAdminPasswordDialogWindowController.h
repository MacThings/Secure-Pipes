//
//  NESAdminPasswordDialogWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/11/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnection.h"
#import "NESKeychain.h"

@interface NESAdminPasswordDialogWindowController : NSWindowController

@property (strong) IBOutlet NSTextField *confirmationTextField;
@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet NSButton *confirmButton;
@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSSecureTextField *passwordField;
@property (strong) IBOutlet NSImageView *image;
@property (weak) NSWindow *parent;

@property (setter = setConfirmationText:,nonatomic) NSString *confirmationText;
@property (setter = setCancelButtonText:,nonatomic) NSString *cancelButtonText;
@property (setter = setConfirmButtonText:,nonatomic) NSString *confirmButtonText;
@property (setter = setWindowImage:,nonatomic) NSImage *windowImage;
@property (setter = setNameFieldText:,nonatomic) NSString *nameFieldText;
@property (strong) IBOutlet NSButton *saveCheckBox;
@property (getter = password, nonatomic) NSString *password;

@property (weak) NESConnection *connection;

- (void) enableSavePassword:(BOOL)enable;

@end
