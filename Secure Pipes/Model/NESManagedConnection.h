//
//  NESManagedConnection.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 8/5/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnection.h"
#import "SocketIO.h"

#define TICKET_SEGMENTS 4
#define TICKET_SEGMENT_LENGTH 4
#define TICKET_REGEX @"([0-9]{4})-([0-9]{4})-([0-9]{4})-([0-9]{4})";

#define TICKET_PATH @"ticket"

@class NESManagedConnectionCommunicator;
@class NESNewManagedConnectionCommunicator;

@interface NESManagedConnection : NESConnection {
    
    NESManagedConnectionCommunicator *communicator;
    NESNewManagedConnectionCommunicator *newCommunicator;

}

- (void)updateConfiguration: (void (^)(NSMutableDictionary *config))completionHandler;
- (void)configUpdated:(NESManagedConnection *)oldConnection;
- (BOOL)isInvalid;


@end

@interface NESManagedConnectionCommunicator : NESManagedConnection {
    NSMutableDictionary *configData;
    NSMutableDictionary *connectionConfig;
    NSMutableDictionary *postResponse;
    NSURLSessionConfiguration *getSessionConfig;
    NSURLSessionDataTask *getTask;
    NSURLSession *configFetchSession;
    NSURL *fetchURL;
    
    NSURLSession *postSession;
    NSURLSessionConfiguration *postSessionConfig;
    NSMutableURLRequest *postRequest;
    NSURLSessionUploadTask *postTask;
    NSURL *postURL;
}

@property(strong) NSString *ticketServer;

- (void)getConnectionConfigForTicket:(NSString *)ticket completionHandler:(void (^)(NSMutableDictionary *config, NSString *errorString))completionHandler;

- (void)getConnectionStatusForConnection:(NESConnection *)connection completionHandler:(void (^)(NSMutableDictionary *config, NSString *errorString))completionHandler;

- (void)postToURLString:(NSString *)url withDictionary:(NSDictionary *)dictionary completionHandler:(void (^)(NSMutableString *errorString)) completionHandler;

- (void)postConnectionStatusForConnection:(NESConnection *)connection completionHandler:(void (^)(NSString *errorString))completionHandler;


@end

@interface NESNewManagedConnectionCommunicator : NESManagedConnection <SocketIODelegate> {
    SocketIO *socket;
}

@property(strong) NSString *ticketServer;
@property(atomic) BOOL connected;

/*
- (void)getConnectionConfigForTicket:(NSString *)ticket completionHandler:(void (^)(NSMutableDictionary *config, NSString *errorString))completionHandler;

- (void)getConnectionStatusForConnection:(NESConnection *)connection completionHandler:(void (^)(NSMutableDictionary *config, NSString *errorString))completionHandler;

- (void)postToURLString:(NSString *)url withDictionary:(NSDictionary *)dictionary completionHandler:(void (^)(NSMutableString *errorString)) completionHandler;

- (void)postConnectionStatusForConnection:(NESConnection *)connection completionHandler:(void (^)(NSString *errorString))completionHandler;
*/
- (void) connect:(void (^)(BOOL success, NSString *error))callback;

- (void) socketIODidConnect:(SocketIO *)socket;
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error;
- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet;
- (void) socketIO:(SocketIO *)socket onError:(NSError *)error;


@end