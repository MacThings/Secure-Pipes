//
//  NESManagedConnectionWindowController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 7/30/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnectionWindowController.h"

@interface NESManagedConnectionWindowController : NESConnectionWindowController {
    NSString *ticket;
    NESManagedConnectionCommunicator *communicator;
}

@property (strong) IBOutlet NSTextField *ticketSegment1;
@property (strong) IBOutlet NSTextField *ticketSegment2;
@property (strong) IBOutlet NSTextField *ticketSegment3;
@property (strong) IBOutlet NSTextField *ticketSegment4;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSImageView *okayImage;



@end
