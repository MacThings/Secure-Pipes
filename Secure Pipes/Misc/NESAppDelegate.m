//
//  nesAppDelegate.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/9/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESAppDelegate.h"
#import "NESPrefsWindowController.h"

@implementation NESAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)awakeFromNib {
    
    // Setup the status bar
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [_statusItem setMenu:_menu];
    [_statusItem setHighlightMode:YES];
    
    if (_controller == nil) {
        _controller = [[NESController alloc] initWithDelegate:self];        
    }
    
    if (_prefsWindowController == nil)
        _prefsWindowController = [[NESPrefsWindowController alloc] initWithWindowNibName:@"Prefs Window"];
    [_prefsWindowController setConnectionList:[_controller connections]];
    [_prefsWindowController setAppConfig:[_controller appConfig]];
    [_prefsWindowController setConnectionManager:[_controller connectionManager]];
    [_prefsWindowController setController:_controller];
    [_prefsWindowController loadWindow];
    [[_prefsWindowController window] close];
    
    // DEBUG
    //[self showPrefsWindow:self];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"SUScheduledCheckInterval"]) {
        // Wenn nicht, setze den Standardwert auf 3600 (1 Stunde)
        [[NSUserDefaults standardUserDefaults] setInteger:3600 forKey:@"SUScheduledCheckInterval"];
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"SUAutomaticallyUpdate"]) {
        // Wenn nicht, setze den Standardwert auf false
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"SUAutomaticallyUpdate"];
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"SUEnableAutomaticChecks"]) {
        // Wenn nicht, setze den Standardwert auf true
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"SUEnableAutomaticChecks"];
    }
    
    
    
    
}

- (IBAction)showPrefsWindow:(id)sender {
    
    //[_controller setConnections:[_prefsWindowController connectionList]]; (Not sure why we had this...)
    [_prefsWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [[_prefsWindowController window ] makeKeyAndOrderFront:nil];
    
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    [_controller fastStopAllConnections];
    return NSTerminateNow;
}
    
- (IBAction)quit:(id)sender {

    if ([[_controller connections] hasActiveConnections]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert setMessageText:NSLocalizedString(@"Are you sure you want to quit Secure Pipes?", nil)];
        [alert setInformativeText:NSLocalizedString(@"Quitting the application will force all active connections to stop.", nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [NSApp activateIgnoringOtherApps:YES];
        NSModalResponse result = [alert runModal];
        [[confirmationDialog window] close];
        if (result == NSAlertSecondButtonReturn) {
            return;
        }        
    }
    
    [NSApp terminate:nil];
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

}

// This is boiler plate for core data, which we decided not to use.
/*
// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "net.edgeservices.Secure_Pipes" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"net.edgeservices.Secure_Pipes"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Secure_Pipes" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Secure_Pipes.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}
*/

@end
