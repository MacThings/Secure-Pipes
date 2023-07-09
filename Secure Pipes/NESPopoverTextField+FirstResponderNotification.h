//
//  NESPopoverTextField+FirstResponderNotification.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/28/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#ifndef Secure_Pipes_NESPopoverTextField_FirstResponderNotification_h
#define Secure_Pipes_NESPopoverTextField_FirstResponderNotification_h

@protocol FirstResponderNotification <NSObject>

@optional
- (void) firstResponderChanged:(NSNotification *)aNotification;
@end


#endif
