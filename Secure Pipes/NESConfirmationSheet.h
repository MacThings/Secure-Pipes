//
//  NESConfirmationSheet.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/10/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NESConfirmationSheet : NSWindowController

@property (strong) IBOutlet NSTextField *confirmationTextField;
@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet NSButton *confirmButton;
@property (strong) IBOutlet NSImageView *image;
@property (weak) IBOutlet NSButton *showAgainBox;
@property (weak) NSWindow *parent;
@property (strong) IBOutlet NSImageView *subImage;

@property (setter = setConfirmationText:,nonatomic) NSString *confirmationText;
@property (setter = setCancelButtonText:,nonatomic) NSString *cancelButtonText;
@property (setter = setConfirmButtonText:,nonatomic) NSString *confirmButtonText;
@property (setter = setWindowImage:,nonatomic) NSImage *windowImage;

- (void) moveStuff;
- (void) setCancelButtonHidden:(BOOL) hidden;

@end
