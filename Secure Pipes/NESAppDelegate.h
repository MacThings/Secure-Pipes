//
//  nesAppDelegate.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/9/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESController.h"
#import "NESConfirmationDialogWindowController.h"

@class NESPrefsWindowController;
@class NESController;

@interface NESAppDelegate : NSObject <NSApplicationDelegate> {

    NESConfirmationDialogWindowController *confirmationDialog;
    
}

@property (strong) NESController *controller;
@property (strong) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *menu;

@property (readonly, strong) NESPrefsWindowController *prefsWindowController;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
