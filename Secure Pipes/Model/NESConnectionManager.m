//
//  NESConnectionManager.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/11/15.
//  Copyright (c) 2015 Timothy Stonis. All rights reserved.
//

#import "NESConnectionManager.h"
#import "NESKeychain.h"

@implementation NESConnectionManager

-(NESConnectionManager *) initWithConnections: (NESConnections *)rootConnections {
    
    self = [super init];
    
    if (self) {
        // Do initiationaliztions here
        _connections = rootConnections;
        [self setConnected:NO];
        [self setRegistered:NO];
        socket = [[SocketIO alloc] initWithDelegate:self];
        workQueue = [[NSMutableArray alloc] init];
        currentRequest = nil;
        requestDisconnect = NO;
        registrationToken = nil;
        newClient = YES;
        rebuild = NO;
        clientInfo = nil;
    }
    
    return self;
}

- (void) deregister:(void(^)(BOOL success, id data))callback {

    if (clientInfo == nil) {
        NSLog(@"ERROR: tried to deregister() without knowing key.");
        _errorCode = NESConnectionManagerCommandFailed;
        [self setError:YES];
        callback(NO, nil);
    }
    
    NSDictionary *options = @{ @"token": registrationToken, @"options" : @{ @"delete-key" : [clientInfo objectForKey:@"delete-key"] } };
    
    [self sendCommand:@"deregister" withData:options andCallback:^(BOOL success, id data) {
        NSDictionary *reply = (NSDictionary *)data;
        NSString *rerror = [data objectForKey:@"error"];
        
        if ((!success)||([rerror isNotEqualTo:[NSNull null]])) {
            NSLog(@"TRANSPORT ERROR: deregister() failed.");
            self->_errorCode = NESConnectionManagerCommandFailed;
            [self setError:YES];
            callback(NO, nil);
        } else {
            NSLog(@"Data result of deregister: %@",reply);
            callback(YES, reply);
        }
        
    }];
    
}

- (void)rebuild {
    
    if (clientInfo != nil) {
        [self deregister:^(BOOL success, id data) {
            if (success) {
                self->clientInfo = nil;
                [self setRegistered:NO];
            }
        }];
    } else {
        
        NSLog(@"ERROR: rebuild() failed. No client info.");
        _errorCode = NESConnectionManagerCommandFailed;
        [self setError:YES];
        
    }
    
}

// Get client info
-(void) clientInfo:(void(^)(BOOL success, id data))callback {
    
    NSDictionary *options = @{ @"token": registrationToken, @"options" : @{ @"full-client-info" : @true, @"uuids" : @[ [uuid UUIDString] ] } };
    
    [self sendCommand:@"clients" withData:options andCallback:^(BOOL success, id data) {
        NSDictionary *reply = (NSDictionary *)data;
        NSString *rerror = [data objectForKey:@"error"];
        
        if ((!success)||([rerror isNotEqualTo:[NSNull null]])) {
            NSLog(@"TRANSPORT ERROR: clients() failed.");
            self->_errorCode = NESConnectionManagerCommandFailed;
            [self setError:YES];
            callback(NO, nil);
        } else {
            self->clientInfo = ((NSArray *)[reply objectForKey:@"data"])[0];
            callback(YES, self->clientInfo);
        }
        
    }];
    
}

// Get client info
-(void) set:(NSString *)key withValue:(NSDictionary *)value andCallback:(void(^)(BOOL success, id data))callback {
    
    NSDictionary *options = @{ @"token": registrationToken, @"value" : value, @"key" : key };
    
    [self sendCommand:@"set" withData:options andCallback:^(BOOL success, id data) {
        NSDictionary *reply = (NSDictionary *)data;
        NSString *rerror = [data objectForKey:@"error"];
        
        if ((!success)||([rerror isNotEqualTo:[NSNull null]])) {
            NSLog(@"TRANSPORT ERROR: set() failed.");
            self->_errorCode = NESConnectionManagerCommandFailed;
            [self setError:YES];
            callback(NO, nil);
        } else {
            NSLog(@"Data result of set: %@",reply);
            callback(YES, reply);
        }
        
    }];
    
}


-(void) registerClient:(NSMutableDictionary *)credentials {

    // We don't know if we're a new client, but will find out after...
    NSDictionary *options = @{ @"new-client" : @true };
    
    // Debug
    rebuild = YES;
    
    [credentials setObject:[uuid UUIDString] forKey:@"uuid"];
    [credentials setObject:[self instanceName] forKey:@"client-name"];
    [credentials addEntriesFromDictionary:options];

    [self sendCommand:@"register" withData:credentials andCallback:^(BOOL success, id data) {
//        NSLog(@"Back from register (%hhd,%@). Do anything in one step, or wait for server to call to us?",success,data);
        
        NSDictionary *reply = (NSDictionary *)data;
        self->registrationToken = [reply objectForKey:@"token"]?:nil;
        if (!self->registrationToken) {
            NSLog(@"Registration (authentication) error: %@",[reply objectForKey:@"error"]);
            self->_errorMessage = [reply objectForKey:@"error"];
            self->_errorCode = NESconnectionManagerErrorAuthenticationFailed;
            [self setError:YES];
        } else {
            // TODO: need to do some verfication on the token here?
            NSLog(@"new-client: %hhd",self->newClient);
            self->newClient = [[reply objectForKey:@"new-client"] boolValue];
            
            // Set the client information
            [self clientInfo:^(BOOL success, id data) {

                if (!success) {
                    NSLog(@"WARNING: Could not get detailed clientInfo.");
                } else {
                    if (!self->newClient&&self->rebuild) {
                        [self rebuild];
                    } else {
                        [self setRegistered:YES];
                    }
                }

            }];
            
        }
        
    }];
    
}

-(void) start {
    
    [self connect:^(BOOL success, NSString *error) {
        if (success) {
            NSLog(@"Connected!");
        } else {
            NSLog(@"Not connected! Error was: %@",error);
            // Here is where we need to queue an error and somehow tell the user..
        }
    }];
}

- (void) stop {
    
    if (_connected) {
        [self setRegistered:NO];
        requestDisconnect = YES;
        [socket disconnect];
    } else if (reconnectTimer) {
        [reconnectTimer invalidate];
        reconnectTimer = nil;
    }
    
}

- (void) pushManagedConnections {
    
    //NSMutableDictionary *cdict = [[NSMutableDictionary alloc] initWithDictionary:[_connections connectionsToDictionary]];
    NSMutableDictionary *tdict = [[NSMutableDictionary alloc] init];

    for (NESConnection *container in [_connections children]) {
        NSMutableArray *conns = [[NSMutableArray alloc] init];
        for (NESConnection *conn in [container children]) {
            if ([[conn configForKey:@"managedConnection"] boolValue]) {
                [conns addObject:[conn configForKey:@"UUID"]];
            }
        }
        [tdict setObject:conns forKey:[container name]];
    }
    
    NSLog(@"Top Level Key: %@",tdict);
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setObject:registrationToken forKey:@"token"];
    [args setObject:[uuid UUIDString] forKey:@"key"];
    [args setObject:tdict forKey:@"value"];
    
    [self sendCommand:@"set" withData:args andCallback:^(BOOL success, id data) {
        NSString *rerror = [data objectForKey:@"error"];
        
        if ((!success)||([rerror isNotEqualTo:[NSNull null]])) {
            NSLog(@"TRANSPORT ERROR: get for key %@ failed.",[self->uuid UUIDString]);
            self->_errorCode = NESConnectionManagerCommandFailed;
            [self setError:YES];
        } else {
            NSLog(@"Top level saved. Now push connections...");
        }
    }];
    
    
}

- (void) processUpdates:(NSDictionary *)updates {
    
    NSInteger errorCount = [[updates valueForKeyPath:@"pending_queue.total_errors"] integerValue];
    NSInteger updateCount = [[updates valueForKeyPath:@"pending_queue.total_updates"] integerValue];
    
    if (errorCount>0) {
        NSLog(@"Server had errors: %@",[updates valueForKeyPath:@"pending_queue.errors"]);
        // TODO: Ack the errors and handle some how...
    } else {
        NSLog(@"No errors from stat()");
    }
    
    if (updateCount >0) {
        NSLog(@"Server had updates: %@",[updates valueForKeyPath:@"pending_queue.updates"]);
    } else {
        NSLog(@"No updates from stat()");
    }
    
    // Get the stored NESConnections or store it if it doesn't exist
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setObject:registrationToken forKey:@"token"];
    [args setObject:[uuid UUIDString] forKey:@"keys"];
    
    [self sendCommand:@"get" withData:args andCallback:^(BOOL success, NSDictionary *data) {
        NSString *rerror = [data objectForKey:@"error"];
        NSDictionary *rdata = [data objectForKey:@"data"];
        
        if ((!success)||([rerror isNotEqualTo:[NSNull null]])) {
            NSLog(@"TRANSPORT ERROR: get for key %@ failed.",[self->uuid UUIDString]);
            self->_errorCode = NESConnectionManagerCommandFailed;
            [self setError:YES];
        } else {
            NSDictionary *key = [rdata objectForKey:[self->uuid UUIDString]];
            NSLog(@"Contents of key %@: %@",[self->uuid UUIDString],key);
            if ([[key objectForKey:@"data"] isEqualTo:[NSNull null]]) {
                NSLog(@"Key data is null, save our data...");
                [self pushManagedConnections];
            } else {
                NSLog(@"Key has data, do our sync...");
            
            }
        }
    }];
    
}

- (NSDictionary *) updateForConnectionUUID:(NSString *)uid fromUpdates:(NSArray *)updates {

    for (NSDictionary *update in updates) {
        if ([[update objectForKey:@"key"] isEqualToString:uid]) {
            return update;
        }

    }
    
    return nil;
}

- (void) syncData:(NSDictionary *)updateData {
    
    NSMutableArray *managedConnections = [_connections getManagedConnections];
    NSArray *updates = [updateData valueForKeyPath:@"pending_queue.updates"];

    // Go through all the mananged connections for config sync
    for (NESConnection *connection in managedConnections) {
        BOOL dirty = [[connection configForKey:@"dirty"] boolValue];
        NSString *connectionUUID = [connection configForKey:@"UUID"];
        
        if (([self updateForConnectionUUID:connectionUUID fromUpdates:updates])&&(dirty)) {
            NSLog(@"UUID %@ has update and local copy is dirty. Need to resolve...",connectionUUID);
        } else if (dirty) {
            // Push to server
            [self set:connectionUUID withValue:[connection connectionConfig] andCallback:^(BOOL success, id data) {
                if (!success) {
                    NSLog(@"Failure to set key %@. Error already should be set.",connectionUUID);
                } else {
                    [connection setConfigForKey:@"dirty" value:NO];
                }
            }];
        }
        
    }
    
    
}

- (void) run {
    
    // If already running, then just return
    if (_running) {
        NSLog(@"ERROR: run called on connection manager when already running");
        return;
    }
    
    [self setRunning:YES];
    
    // First thing is to stat the remote object store
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setObject:registrationToken forKey:@"token"];
    
    [self sendCommand:@"stat" withData:args andCallback:^(BOOL success, id data) {
        
        if ((!success)||(!data)) {
            NSLog(@"ERROR: stat on remote store failed (1)");
            self->_errorMessage = NSLocalizedString(@"stat on remote store failed", nil);
            self->_errorCode = NESconnectionManagerErrorStatFailed;
            [self setError:YES];
            return;
        }
        
        NSDictionary *reply = (NSDictionary *)data;
        
        if ([reply objectForKey:@"error"] == nil) {
            NSLog(@"ERROR: stat on remote store failed (2)");
            self->_errorMessage = [reply objectForKey:@"error"];
            self->_errorCode = NESconnectionManagerErrorStatFailed;
            [self setError:YES];
            return;
        } else {
            //NSLog(@"REPLY DICTIONARY: %@",reply);
            [self syncData:reply];
            return;
        }
        
        
    }];
    
    
    
}

- (void) setRunning:(BOOL)running {
    
    // Stop anything going on...
    _running = running;
    
}

- (void) setRegistered:(BOOL)registered {

    if (!registered) {
        registrationToken = nil;
        clientInfo = nil;
    }
    
    if (registered&&!_connected) {
        NSLog(@"ERROR: Cannot set registered with not connected!");
        _registered = NO;
        return;
    }
    
    _registered = registered;
    
}

- (void) setAppConfig:(NESAppConfig *)appConfig {
    
    _appConfig = appConfig;
    
    // Get our server
    if ([_appConfig configForKey:@"defaultManagedConnectionServer"]) {
        serverURL = [NSURL URLWithString:[appConfig configForKey:@"defaultManagedConnectionServer"]];
    }
    
    // We need a UUID for this instance
    if (![_appConfig configForKey:@"instanceUUID"]) {
        uuid = [[NSUUID alloc] init];
        [_appConfig setConfigForKey:@"instanceUUID" withValue:[uuid UUIDString]];
        [_appConfig saveConfig];
    } else {
        uuid = [[NSUUID alloc] initWithUUIDString:[_appConfig configForKey:@"instanceUUID"]];
    }
    
}

-(NSString *) instanceName {
    
    if (_appConfig == nil) {
        return nil;
    } else {
        return [_appConfig configForKey:@"managedInstanceName"];
    }
    
}

-(BOOL) isRegistered {

    return _registered;

}

-(BOOL) isConnected {

    return _connected;

}

-(BOOL) isRunning {
    
    return _running;
    
}

- (int) getDelayInSeconds {
    
    // TODO: We should eventually make this at least configurable or some backoff algorithm
    return 10;
}

- (void) setDisconnectAndRetry {

    [self setConnected:NO];
    [self setRunning:NO];

    if (!requestDisconnect&&_reconnectOnDisconnect) {
        NSLog(@"Retrying connection...");
        reconnectTimer = [NSTimer timerWithTimeInterval:[self getDelayInSeconds] target:self selector:@selector(reconnectTimerExpired:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:reconnectTimer forMode:NSDefaultRunLoopMode];
    } else {
        reconnectTimer = nil;
        requestDisconnect = NO;
    }

}

- (void) reconnectTimerExpired:(NSTimer *) timer {

    NSLog(@"Timer expired, reconnecting to management server...");
    reconnectTimer = nil;
    if (!_connected) {
        [self start];
    }
    
}

- (void) connect:(void (^)(BOOL success, NSString *error))callback {
    
    if (!serverURL) {
        callback(NO,@"No ticket server not specified.");
        return;
    }
    
    if ([[serverURL scheme] isEqualToString:@"https"]) {
        [socket setUseSecure:YES];
    }
    
    [socket setPath:[serverURL path]];
    [socket setReturnAllDataFromAck:YES];
    [socket connectToHost:[serverURL host] onPort:[[serverURL port] integerValue]];
    
}

- (void) sendCommand:(NSString *)command withData:(id)data andCallback:(void(^)(BOOL success, id data))callback {
    
    NESConnectionManagerRequest *request = [[NESConnectionManagerRequest alloc] init];
    [request setCommand:command];
    [request setData:data];
    [request setCallback:callback];
    [workQueue addObject:request];
    [self runQueue];
}

- (void) runQueue {

    if ([workQueue count]>0) {

        if ((!_connected) || (!socket)) {
            NSLog(@"ERROR: queue can't be processed because not connected or no socket object");
            // TODO: Rety at some other time?
        }

        // Maybe need a lock here?
        if (currentRequest != nil) {
            NSLog(@"Queue ran while busy.");
            // We should get called again when the current request is finished
            return;
        }
        currentRequest = [workQueue objectAtIndex:0];
        [workQueue removeObjectAtIndex:0];
        [currentRequest setState:NESMR_PROCESSING];
        [socket sendEvent:[currentRequest command] withData:[currentRequest data] andAcknowledge:^(id argsData) {
            [self->currentRequest setState:NESMR_COMPLETED];
            void(^callback)(BOOL,id) = [self->currentRequest callback];
            self->currentRequest = nil;
            [self runQueue];
            if (callback) {
                callback(YES,argsData);
            }
            
        }];

        
    }
    
}

#pragma mark SocketIO Delegate

-(void) socketIODidConnect:(SocketIO *)socket {
    
    NSLog(@"Connected!");
    [self setConnected:YES];
    [self runQueue];
    
}

-(void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"Disconnected! Error: %@",error);
    [self setDisconnectAndRetry];
}

-(void) socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"Socket Error: %@",error);
    [self setDisconnectAndRetry];
}

-(void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    NSLog(@"Socket ReceiveMessage: %@",[packet data]);
    
}
-(void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    NSLog(@"Socket Event: %@",[packet data]);
    
}

-(void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    NSLog(@"Socket JSON: %@",[packet data]);
    
}

-(void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    NSLog(@"Socket SentMessage type: %@",[packet type]);
    
}


@end

@implementation NESConnectionManagerRequest




@end
