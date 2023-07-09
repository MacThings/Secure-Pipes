//
//  NESConfirmationDialogWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 4/5/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NESConfirmationDialogWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *confirmationTextField;
@property (weak) IBOutlet NSButton *denyButton;
@property (weak) IBOutlet NSButton *confirmButton;
@property (weak) IBOutlet NSTextField *subTextField;

@property (setter = setConfirmationText:,nonatomic) NSString *confirmationText;
@property (setter = setSubText:,nonatomic) NSString *subText;


@end
