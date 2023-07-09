//
//  NESConnectionProcess.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/6/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NESConnection.h"

@interface NESConnectionProcess : NSObject {
    NSFileHandle *_handle;
    NSPipe *output;
}

@property (weak) NESConnection *connection;
@property (strong) NSTask *process;
@property (assign) BOOL isRunning;
@property (strong) NSString *passwd;

- (id) initWithConnection: (NESConnection *) connection;
- (void) startConnection;
- (void) stopConnection:(BOOL) waitForExit;
- (void) hardStopConnection;

@end

