//
//  NESManagedConnection.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 8/5/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESManagedConnection.h"
#import "NESUser.h"
#import "SocketIO.h"

NSString * const ticketPath = TICKET_PATH;

@implementation NESManagedConnection

- (id)initWithName:(NSString *)name asType:(NSInteger)conType andConfig:(NSDictionary *) config {
    
    self = [super initWithName:name asType:conType andConfig:config];
        
    if (self) {
    
        communicator = [[NESManagedConnectionCommunicator alloc] init];
        [communicator setTicketServer:[config valueForKey:@"managedConnectionServer"]];
        
        switch (conType) {
            case NESConnectionManagedProxy:
                ;
                break;
            default:
                break;
        }
        
        if ([self isInvalid]) {
            [[self connectionStatus] setObject:@(NESConnectionInvalid) forKey:@"currentStatus"];
        }
        
    }
    
    return self;
}

- (BOOL) hasNetworkRelatedChange:(NESManagedConnection *)oldConnection {
    
    NSArray *networkKeys = @[ @"sshServer", @"sshUsername", @"sshPort", @"localBindAddress", @"localBindPort",@"autoConfigProxy",@"strictHostKeys",@"useCustomIdentityEnabled"];
    
    for (id key in networkKeys) {
        NSString *newValue = ([[self configForKey:key] respondsToSelector:@selector(stringValue)])?[[self configForKey:key] stringValue]:[self configForKey:key];
        NSString *oldValue = ([[oldConnection configForKey:key] respondsToSelector:@selector(stringValue)])?[[oldConnection configForKey:key] stringValue]:[oldConnection configForKey:key];
        
        if (![newValue isEqualToString:oldValue]) {
            NSLog(@"Need restart for key difference of %@ (%@ <> %@)",key,oldValue,newValue);
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) isInvalid {
    
    if ([self configForKey:@"invalid"] != nil) {
        return YES;
    } else {
        return NO;
        
    }
}

- (void)configUpdated:(NESManagedConnection *)oldConnection {
    
    
    switch ([oldConnection isInvalid]) {

        case true:
            if (![self isInvalid]) {
                [self queueStatusUpdate:NESConnectionConfigRevalidated withData:@"Configuration revalidated"];
            } else {
                NSLog(@"Unhandled config update (no re-validation on updating invalid ticket)");
            }
            
            break;

        
        case false:
            if ([self isInvalid]) {
                [self queueStatusUpdate:NESConnectionConfigInvalidated withData:@"Configuration invalided"];
            } else if ([self hasNetworkRelatedChange:oldConnection]) {
                [self queueStatusUpdate:NESConnectionNetworkConfigChanged withData:@"Need to restart due to network change!"];
            } else {
                // Just some "other" change in the config (like name, etc)
                NSLog(@"Unhandled config update (or no need to do anything)");
            }
            break;
    }
    
}

- (void)updateConfiguration: (void (^)(NSMutableDictionary *config))completionHandler {
    
    [communicator getConnectionStatusForConnection:self completionHandler:^(NSMutableDictionary *config, NSString *errorString) {
        if (config != nil) {
            int serverVersion = [[config objectForKey:@"revision"] intValue];
            int localVersion = [[[self connectionConfig] objectForKey:@"revision"] intValue];
            
            if (serverVersion > localVersion) {
                // Install the new configuration
                NSLog(@"Local version < server version - Saving ticket");
                completionHandler(config);
                
            } else if (localVersion > serverVersion) {
                NSLog(@"Local version > server version - Posting ticket");
                // Push local config here and update status if needed
                [communicator postConnectionStatusForConnection:self completionHandler:^(NSString *serverErrorString) {
                    if (serverErrorString) {
                        NSLog(@"Error posting config!");
                        //[self setStatus:NESConnectionInvalidated];
                        [self queueStatusUpdate:NESConnectionSyncFailure withData:[NSString stringWithFormat:NSLocalizedString(@"Unable to post updated configuration to server. Error from the server was: \"%@\"", nil),serverErrorString]];

                    } else {
                        
                        [self queueStatusUpdate:NESConnectionSyncOk withData:@"Sync okay (posted local config)"];
                        completionHandler(nil);
                    }
                }];
            } else {
                NSString *serverModifier = [config objectForKey:@"lastRevisionBy"];
                NSString *localModifier = [[self connectionConfig] objectForKey:@"lastRevisionBy"];
                
                NSLog(@"Local version = server version - Check to see if split brained...");
                if ((![localModifier isEqualToString:serverModifier]) && (![serverModifier isEqualToString:@"macClient"])) {
                    // Install the new configuration
                    NSLog(@"Local version modified, but server version rules - Saving ticket");
                    [self queueStatusUpdate:NESConnectionSyncConflict withData:@"Sync conflict, but server wins!"];
                    completionHandler(config);
                    
                } else {
                    [self queueStatusUpdate:NESConnectionSyncOk withData:@"Sync okay"];
                    completionHandler(nil);
                }
            }
        } else {
            NSLog(@"Error fetching config!");
            //[self setStatus:NESConnectionSyncFailure];
            errorString = NSLocalizedString(@"Unable to get managed connection configuration from remote server.", nil);
            [self queueStatusUpdate:NESConnectionSyncFailure withData:errorString];
            completionHandler(nil);
        }
    }];
    
}


@end

@implementation NESManagedConnectionCommunicator

- (id)init {
    
    self = [super init];
    
    if (self) {
        configData = nil;
    }
    
    return self;
    
}

- (void)postToURLString:(NSString *)url withDictionary:(NSDictionary *)dictionary completionHandler:(void (^)(NSMutableString *errorString)) completionHandler {

    NSMutableString *errorString = [[NSMutableString alloc] init];
    NSError *jsonError = NULL;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    if (jsonError != nil) {
        NSLog(@"Error converting post dictionary to data!");
        [errorString setString:[jsonError localizedDescription]];
        completionHandler(errorString);
        return;
    }
        
    postURL = [[NSURL alloc] initWithString:url];
    postRequest = [NSMutableURLRequest requestWithURL:postURL];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    postSessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    postSession = [NSURLSession sessionWithConfiguration:postSessionConfig delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    postTask = [postSession uploadTaskWithRequest:postRequest fromData:JSONData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"Protocol error saving config to server.");
            [errorString setString:[error description]];
            completionHandler(errorString);
        } else {
            NSError *jsonError = nil;
            postResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            
            if (jsonError) {
                [errorString setString:[jsonError description]];
                completionHandler(errorString);
            } else {
                completionHandler(nil);
            }
        }
        
    }];
    
    [postTask resume];
    
}

- (void)getDictionaryFromURLString:(NSString *)url completionHandler:(void (^)(NSMutableString *errorString))completionHandler {
    
    NSMutableString *errorString = [[NSMutableString alloc] init];
    
    getSessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configFetchSession = [NSURLSession sessionWithConfiguration:getSessionConfig delegate:nil delegateQueue:[NSOperationQueue currentQueue]];
    fetchURL = [[NSURL alloc] initWithString:url];
    getTask = [configFetchSession dataTaskWithURL:fetchURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError = NULL;
        NSLog(@"In Completion handler...");
        if (error != nil) {
            NSLog(@"Error getting JSON config from server: %@",error);
            [errorString setString:@"There was an error communicating with the ticket server. Please check your network connection/settings and retry your request."];
        } else {
            configData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"Error converting JSON config from server: %@",jsonError);
                [errorString setString:@"The ticket server returned a malformed response. Please retry your request or contact the ticket vendor for support."];
            } else {
                completionHandler(errorString);
                return;
            }
        }
        configData = nil;
        completionHandler(errorString);
        
    }];
    
    // Go get the data
    [getTask resume];
    
}

- (NSMutableDictionary *)mungeManagedProxyConfigFromServer:(NSMutableDictionary *)config withErrorString:(NSMutableString *) errorString {
    
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
    //NSNumber *version = [dict objectForKey:@"CFBundleShortVersionString"] numberFr;
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    NSNumber *clientVersion = [nf numberFromString:[dict objectForKey:@"CFBundleShortVersionString"]];
    NSNumber *configVersion = (NSNumber *)[config objectForKey:@"minClientVersion"];
    
    if ([clientVersion compare:configVersion] == NSOrderedAscending) {
        NSLog(@"ERROR: Client too old!");
        [errorString setString:@"This version of Secure Pipes does not support the requested ticket. Please upgrade to a newer version."];
        return nil;
    }
    
    // Can't auto-config proxy if not admin
    if (![[NESUser currentUser] isMemberOfAdminGroup]) {
        [config setValue:@false forKey:@"autoConfigProxy"];
    }
    
    return config;
}

- (void)getConnectionStatusForConnection:(NESConnection *)connection completionHandler:(void (^)(NSMutableDictionary *config, NSString *errorString))completionHandler {

    NSString *uuid = [connection configForKey:@"UUID"];
    NSString *ticket = [connection configForKey:@"ticketNumber"];
    NSString *statusURL = [NSString stringWithFormat:@"%@/%@/%@/%@/status",_ticketServer,ticketPath,ticket,uuid];
    
    [self getDictionaryFromURLString:statusURL completionHandler:^(NSMutableString *errorString) {
        if (configData == nil) {
            completionHandler(nil, errorString);
        } else {
            NSLog(@"Config from JSON: %@",configData);
            if ([[configData objectForKey:@"statusCode"] intValue] == 500) {
                [errorString setString:@"There is a problem with this ticket."];
                NSLog(@"This ticket has a problem: %@",[configData objectForKey:@"errorMessage"]);
            } else if ([[configData objectForKey:@"statusCode"] intValue] == 404) {
                [errorString setString:@"This ticket number supplied cannot be found."];
            } else {
                // Do some ticket validation here? (Yes, see below)
                completionHandler(configData,errorString);
                return;
            }
            completionHandler(nil,errorString);
        }
    }];

    
}

- (void)postConnectionStatusForConnection:(NESConnection *)connection completionHandler:(void (^)(NSString *errorString))completionHandler {

    NSString *uuid = [connection configForKey:@"UUID"];
    NSString *registerURL = [NSString stringWithFormat:@"%@/%@/%@/%@/update",_ticketServer,ticketPath,[connection configForKey:@"ticketNumber"],uuid];
    
    [self postToURLString:registerURL withDictionary:[connection connectionConfig] completionHandler:^(NSMutableString *errorString) {
        
        if (errorString != nil) {
            NSLog(@"Error was: %@",errorString);
            completionHandler(errorString);
        } else {
            // Post succeded, let's check application level response.
            if (postResponse != nil) {
                int statusCode = [[postResponse objectForKey:@"statusCode"] intValue];
                
                if (statusCode == 500) {
                    errorString = [[NSMutableString alloc] init];
                    [errorString setString:[NSString stringWithFormat:NSLocalizedString(@"There was an error updating the configuration on the server: %@", nil),[postResponse objectForKey:@"errorMessage"]]];
                }
            }
            postResponse = nil;
            completionHandler(errorString);
        }
        
    }];
    
}


- (void)getConnectionConfigForTicket:(NSString *)ticket completionHandler:(void (^)(NSMutableDictionary *, NSString *))completionHandler {
    
    NSString *uuid = [NESConnection generateConnectionUUID];
    NSString *registerURL = [NSString stringWithFormat:@"%@/%@/%@/%@/register",_ticketServer,ticketPath,ticket,uuid];
    
    [self getDictionaryFromURLString:registerURL completionHandler:^(NSMutableString *errorString) {
        if (configData == nil) {
            completionHandler(nil, errorString);
        } else {
            NSLog(@"Config from JSON: %@",configData);
            if ([[configData objectForKey:@"statusCode"] intValue] == 500) {
                [errorString setString:@"This ticket number supplied is already in use or expired. Please contact the ticket vendor for a new ticket."];
                NSLog(@"This ticket has a problem: %@",[configData objectForKey:@"errorMessage"]);
            } else if ([[configData objectForKey:@"statusCode"] intValue] == 501) {
                [errorString setString:@"There was a problem configuring the SSH server for this ticket. Please contact the ticket vendor or try again later."];
            } else if ([[configData objectForKey:@"statusCode"] intValue] == 404) {
                [errorString setString:@"This ticket number supplied cannot be found. Please check the number or contact the ticket vendor for a new ticket."];
            } else if ([[configData objectForKey:@"statusCode"] intValue] == 502) {
                [errorString setString:@"This version of Secure Pipes does not support the requested ticket. Please upgrade to a newer version."];
            } else {
                // Do some ticket validation here? (Yes, see below)
                configData = [self mungeManagedProxyConfigFromServer:configData withErrorString:errorString];
                completionHandler(configData,errorString);
                return;
            }
            completionHandler(nil,errorString);
        }
    }];
    
}

@end


@implementation NESNewManagedConnectionCommunicator

- (id)init {
    
    self = [super init];
    if (self) {
        // Do any initializations here
        socket = [[SocketIO alloc] initWithDelegate:self];
        _connected = NO;
    }
    
    return self;
}

- (void) connect:(void (^)(BOOL success, NSString *error))callback {

    if (!_ticketServer) {
        callback(NO,@"No ticket server not specified.");
        return;
    }
    
    NSURL *url = [NSURL URLWithString:_ticketServer];
    
    if ([[url scheme] isEqualToString:@"https"]) {
        [socket setUseSecure:YES];
    }
    
    [socket setPath:[url path]];
//    [socket connectToHost:[url host] onPort:[[url port] integerValue] withParams:nil withNamespace:@"/ticket"];
    [socket connectToHost:[url host] onPort:[[url port] integerValue]];
    
}

-(void) socketIODidConnect:(SocketIO *)socket {
    
    NSLog(@"Connected!");
    [self setConnected:YES];
    
}

-(void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"Disconnected! Error: %@",error);
    [self setConnected:NO];
}

-(void) socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"Socket Error: %@",error);
    [self setConnected:NO];
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
