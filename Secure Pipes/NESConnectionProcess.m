//
//  NESConnectionProcess.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/6/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnectionProcess.h"

@implementation NESConnectionProcess

- (id) initWithConnection: (NESConnection *) connection {
    
    self = [super init];
    
    if (self) {
        _connection = connection;
        _isRunning = NO;
        _process = nil;
        _handle = nil;
        _passwd = nil;
    }
    
    return self;
}

- (void) startConnection {

    if (_process)  {
        NSLog(@"Error: Process already allocated for %@ - should be thrown away after terminating.",[_connection name]);
        return;
    } else {
        _process = [[NSTask alloc] init];
    }
    
    output = [[NSPipe alloc] init];
    NSMutableArray *args = [[NSMutableArray alloc] init];

    // Setup the path
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/ssh_manager.exp"];
    NSLog(@"PATH: %@",path);
    [_process setLaunchPath: path];
    
    NSString *filename = [[NSString alloc] initWithFormat:@"%@/%@.ssh_config",SUPPORT_DIR,[_connection configForKey:@"UUID"]];
    filename = [filename stringByExpandingTildeInPath];
    [args addObjectsFromArray:@[@"-c", filename,
                                @"-i",[_connection configForKey:@"UUID"],
                                @"-t",[NSString stringWithFormat:@"%ld",[_connection type]]]];
    
    NSString *fingerPrint = [_connection configForKey:@"hostKeyFingerPrint"];
    if (fingerPrint) {
        [args addObjectsFromArray:@[@"-f", fingerPrint]];
        [_connection setConfigForKey:@"hostKeyFingerPrint" value:nil];
    }
    
    switch ([_connection type]) {
        case NESConnectionLocalForward:
        case NESConnectionProxy:
        case NESConnectionManagedProxy:
            if ([[_connection configForKey:@"localBindPort"] integerValue] < 1024) {
                [args addObject:@"--needs-sudo"];
            }
        break;
        default:
        break;
    }

    if ((([_connection type] == NESConnectionProxy) || ([_connection type] == NESConnectionManagedProxy))
        && ([[_connection configForKey:@"autoConfigProxy"] boolValue] == YES)) {
        [args addObject:@"-p"];
        NSString *bindAddress = [[_connection configForKey:@"localBindAddress"] isEqualToString:@"*"]?@"localhost":[_connection configForKey:@"localBindAddress"];
        [args addObject:[NSString stringWithFormat:@"%@:%@",bindAddress,[_connection configForKey:@"localBindPort"] ]];
    }
    
    if (([_connection type] == NESConnectionLocalForward) && ([[_connection configForKey:@"useBonjour"] boolValue] == YES)
        && ([[_connection configForKey:@"bonjourServiceName"] isEqualToString:@"home-sharing"])) {
        [args addObject:@"-m"];
        [args addObject:[_connection configForKey:@"remoteHost"]];
    }
    
    NSLog(@"ARGS: %@",args);
    [_process setArguments:args];
    
    //[_process setStandardError:output];
    [_process setStandardOutput:output];
    _handle = [output fileHandleForReading];
    
    [_handle waitForDataInBackgroundAndNotify];

    // Setup the environment variables
    NSMutableDictionary *env = [[NSMutableDictionary alloc] initWithDictionary:[_process environment]];
    NSString *passwd = [_connection configForKey:@"sshPassword"];
    [env setObject:(passwd?passwd:@"") forKey:@"SSH_PASSWD"];
    if ([_connection needsAdministratorRights]) {
        if (_passwd == nil) {
            [_connection queueStatusUpdate:NESConnectionError withData:NSLocalizedString(@"An administrative password for this computer is required for this connection. Please enter the password when starting the connection.", nil)];
            return;
        } else {
            [env setObject:_passwd forKey:@"ADMIN_PASSWD"];
        }
    }
    
    if ([[_connection configForKey:@"httpProxyNeedsPassword"] integerValue] == YES) {
        NSString *userPass = [[[_connection configForKey:@"httpProxyUsername"] stringByAppendingString:@":"] stringByAppendingString:[_connection configForKey:@"httpProxyPassword"]];
        [env setObject:userPass forKey:@"PROXY_UP"];
    }
    
    NSString *workDir = [SUPPORT_DIR stringByExpandingTildeInPath];
    [env setObject:workDir forKey:@"WORKING_DIR"];
    [env setObject:[[NSBundle mainBundle] resourcePath] forKey:@"SCRIPT_PATH"];
    [env setObject:[[NSBundle mainBundle] resourcePath] forKey:@"HOME"];
    [_process setEnvironment:env];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    [_process setTerminationHandler:^(NSTask *task) {
        NSLog(@"Terminator being called: %@",[[weakSelf connection] name]);
        [weakSelf performSelectorOnMainThread:@selector(connectionTerminated:) withObject:nil waitUntilDone:YES];
        //[weakSelf connectionTerminated:nil];
    }];
    
    [[_process.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        [self performSelectorOnMainThread:@selector(receivedData:) withObject:nil waitUntilDone:YES];
    }];
    
    
    [_process performSelectorOnMainThread:@selector(launch) withObject:nil waitUntilDone:NO];
    _isRunning = YES;
    
}

- (void)receivedData:(NSNotification *)notif {

    
    NSData *data = [_handle availableData];
    
    if ([data length] == 0)
        return;
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self processDataLines:str];

}

- (NSArray *)splitLines:(NSString *) data {
    
    NSRange newlineLocation;
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    
    while ((newlineLocation = [data rangeOfString:@"\n"]).location != NSNotFound) {
        NSRange line = NSMakeRange(0, newlineLocation.location+1);
        [lines addObject:[data substringWithRange:line]];
        data = [data stringByReplacingCharactersInRange:line withString:@""];
    }

    return lines;
}

- (void) processDataLines:(NSString *) data {
    
    NSArray *lines = [self splitLines:data];
    
    for (id line in lines) {
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(STATE|EXIT|PID|SPID|INFO):(\\d+)\\|(.*)\\|(.*)$" options:NSRegularExpressionCaseInsensitive error:&error];
        
        NSArray *matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
        if ([matches count] > 0) {
            for (NSTextCheckingResult *match in matches) {
                NSString *tag = [line substringWithRange:[match rangeAtIndex:1]];
                NSString *code = [line substringWithRange:[match rangeAtIndex:2]];
                NSString *description = [line substringWithRange:[match rangeAtIndex:3]];
                NSString *args = [line substringWithRange:[match rangeAtIndex:4]];
                if (([tag isEqualToString:@"PID"])||([tag isEqualToString:@"SPID"])) {
                    [_connection setStatusForKey:tag value:code];
                    [_connection queueStatusUpdate:NESConnectionConnecting withData:nil];
                } else if ([tag isEqualToString:@"STATE"]) {
                    NSLog(@"STATE Message Received: %ld",[code integerValue]&CONNECTION_STATE_MASK);
                    if ([code integerValue]&NESConnectionConnected) {
                        [_connection queueStatusUpdate:NESConnectionConnected withData:description];
                    }
                } else if ([tag isEqualToString:@"EXIT"]) {
                    NSLog(@"EXIT Message Received: %@",description);
                    switch ([code integerValue]) {
                            // TODO: Make these into defined constants with good error messages.
                            case 0:
                            case 2:
                            case 28:
                            [_connection queueStatusUpdate:NESConnectionIdle withData:description];
                            break;
                            case 23:
                            NSLog(@"ARGS: %@",args);
                            [_connection queueStatusUpdate:NESConnectionUnknownKey withData:description andArgs: args];
                            break;
                            case 26:
                            [_connection queueStatusUpdate:NESConnectionKeyChanged withData:description andArgs: args];
                            break;
                            case 16:
                            case 19:
                            case 3:
                            NSLog(@"ARGS: %@",args);
                            [_connection queueStatusUpdate:NESConnectionAuthenticationFailed withData:description andArgs: args];
                            break;
                            case 35:
                            NSLog(@"ARGS: %@",args);
                            description = [description stringByAppendingFormat:@"\r\n\r\nConnection UUID: %@", args];
                            [_connection queueStatusUpdate:NESConnectionError withData:description andArgs: args];
                            break;
                        default:
                            NSLog(@"Queuing a connection error...");
                            [_connection queueStatusUpdate:NESConnectionError withData:description];
                            break;
                    }
                    NSLog(@"Exiting");
                } else if ([tag isEqualToString:@"INFO"]) {
                    NSLog(@"INFO Message Received: %@ with code: %ld",description,(long)[code integerValue]);
                    switch ([code integerValue]) {
                        // This is the home-sharing info coming back
                        case 100:
                            [_connection queueStatusUpdate:NESConnectionInfoReceived withData:description andArgs:args];
                            break;
                            
                        default:
                            [_connection queueStatusUpdate:NESConnectionInfoReceived withData:description];
                            break;
                    }
                }
                
            }
            
        } else {
            NSLog(@"Flow (%@): %@",[_connection name],line);
        }
    }

}

- (void) hardStopConnection {
    pid_t pid = (pid_t)[[[_connection connectionStatus] objectForKey:@"PID"] integerValue];
    
    if ([_process isRunning]) {
        NSLog(@"Sending %d of %@ a kill signal...",pid,[_connection name]);
        kill(pid, SIGKILL); // Don't be nice about it...
        [_process terminate];
        NSLog(@"Done!");
    }


}

- (void) stopConnection:(BOOL) waitForExit {
    pid_t pid = (pid_t)[[[_connection connectionStatus] objectForKey:@"PID"] integerValue];
    
    if (pid) {
        if ([_process isRunning]) {
            NSLog(@"Sending %d of %@ a kill signal...",pid,[_connection name]);
            [_process terminate];
            if (waitForExit) {
                [_process waitUntilExit];
            }
            NSLog(@"Done!");
        } else {
            NSLog(@"Stopping connection, but process wasn't running (no kill signal)...");
        }
    } else {
        // TODO: Is this a race connection if someone tries to cancel a connecting process too quickly?
        NSLog(@"WARNING: PID is 0, not trying to kill ourselves. (Process must not have started yet).");
    }

}

- (void)connectionTerminated:(NSNotification *)notif {

    NSLog(@"TERMINATED: %@, connectionTerminated called - running: %d",[_connection name],[_process isRunning]);

    NSTask *task2 = [notif object];
    NSTask *task = _process;

    if (!_process) {
        NSLog(@"Termination called twice?!?!?! %d",[task2 processIdentifier]);
        return;
    }
    
    if ([_process isRunning]) {
        NSLog(@"ERROR: Termination called while process running, will get data and wait BUT THIS MAY HANG!");
        [_process waitUntilExit];
    }
    
    [_process setTerminationHandler:nil];
    [[_process.standardOutput fileHandleForReading] setReadabilityHandler:nil];
    
    NSLog(@"Connection %@ terminated with status %u %@ reason: %ld...",[_connection name],[task terminationStatus],[notif name],[task terminationReason]);
    if ([task terminationReason] == NSTaskTerminationReasonUncaughtSignal) {
        [_connection queueStatusUpdate:NESConnectionError withData:NSLocalizedString(@"SSH process killed unexpectedly.", nil)];
    }
    
    if (([task terminationReason] == NSTaskTerminationReasonExit) && ([task terminationStatus] == 1)) {
        [_connection queueStatusUpdate:NESConnectionError withData:NSLocalizedString(@"SSH process exited with error. Check the connection and server configuration parameters.", nil)];
    }
    
    _isRunning = NO;

    // Get what's left in the buffer, since we deregistered for data notifications...
    NSData *data = [_handle availableData];
    while ([data length] > 0) {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"Processing remaining data from process...");
        [self processDataLines:str];
        data = [_handle availableData];
    }
    
    NSLog(@"No Data from process left to process, check status");
    if (([_connection status]&NESConnectionConnected)||([_connection status]&NESConnectionConnecting)) {
            pid_t pid = (pid_t)[[[_connection connectionStatus] objectForKey:@"PID"] integerValue];
            NSLog(@"THIS SHOULD NOT HAPPEN, but may... (SSH process died, but we say connection running. PID = %d)",pid);
        }
    
    NSLog(@"Cleaning up process variables...");
    _process = nil;
    _handle = nil;
    output = nil;

}




@end
