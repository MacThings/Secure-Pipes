//
//  NESController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/3/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NESConnection.h"
#import "NESAppDelegate.h"
#import "NESMenuIconController.h"
#import "NESAdminPasswordDialogWindowController.h"
#import "NESConfirmationDialogWindowController.h"
#import "NESConnectionProcess.h"
#import "NESAppConfig.h"
#import "NESConnectionManager.h"

@class NESAppDelegate;

@interface NESController : NSObject {
    NESAdminPasswordDialogWindowController *passwordDialog;
    NESConfirmationDialogWindowController *confirmationDialog;
    NSLock *notificationLock;
}

@property (atomic,strong) NESConnections *connections;
@property (atomic,strong) NESConnectionManager *connectionManager;
@property (atomic,strong) NESAppConfig *appConfig;
@property (atomic,strong) NESAppDelegate *appDelegate;
@property (atomic,strong) NESMenuIconController *iconController;

-(id) initWithDelegate: (NESAppDelegate *)delegate;
-(void) stopAllConnections;
-(void) fastStopAllConnections;
- (void) toggleConnection: (NSMenuItem *) menuItem;
//- (NSMenuItem *) newMenuForConnection:(NESConnection *) connection;

@end
