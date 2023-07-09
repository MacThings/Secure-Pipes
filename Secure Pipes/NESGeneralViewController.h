//
//  NESGeneralViewController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/13/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESAppConfig.h"
#import "NESKeychain.h"
#import "NESConnectionManager.h"
#import "NESManagedRegistrationSheet.h"

@interface NESGeneralViewController : NSViewController <NSTextFieldDelegate> {
    NSString *defaultName;
    NESManagedRegistrationSheet *registrationSheet;
}

@property (strong) NSMutableDictionary *config;
@property (strong, setter = setAppConfig:,nonatomic) NESAppConfig *appConfig;
@property (strong) NESConnectionManager *connectionManager;
@property (strong) IBOutlet NSButton *loginLaunchCheckBox;
@property (strong) IBOutlet NSButton *useNotificationCenterCheckBox;
@property (strong) IBOutlet NSButton *allowSavePasswordCheckBox;
@property (strong) IBOutlet NSButton *reconnectAtLoginCheckBox;
@property (strong) IBOutlet NSButton *enableMangedConnectionsCheckBox;
@property (strong) IBOutlet NSTextField *managedInstanceName;
@property (strong) IBOutlet NSButton *registerButton;
@property (strong) IBOutlet NSImageView *managedStatusLight;
@property (strong) IBOutlet NSProgressIndicator *managedProgressIndicator;
@property (strong) IBOutlet NSTextField *connectionManagerErrorMessage;

- (IBAction)checkAction:(NSButton *)sender;
- (IBAction)registerAction:(NSBundle *)sender;

@end
