//
//  NESConnectionCellView.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/19/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESPopoverButton.h"

@interface NESConnectionCellView : NSTableCellView

@property (strong) IBOutlet NSImageView *statusLight;
@property (strong) IBOutlet NSProgressIndicator *busyIndicator;
@property (strong) IBOutlet NSTextField *connectionName;
@property (strong) IBOutlet NSTextField *serverName;

@property (strong) IBOutlet NESPopoverButton *infoPopupButton;

@end
