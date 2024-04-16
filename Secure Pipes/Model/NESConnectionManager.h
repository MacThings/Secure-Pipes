//
//  NESConnectionManager.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/11/15.
//  Copyright (c) 2015 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnection.h"
#import "NESAppConfig.h"
#import "SocketIO.h"

typedef NS_ENUM(NSInteger,NESConnectionManagerErrorCodeType) {
    NESconnectionManagerErrorRegistrationFailed,
    NESconnectionManagerErrorAuthenticationFailed,
    NESconnectionManagerErrorStatFailed,
    NESConnectionManagerCommandFailed
};


@class NESConnectionManagerRequest;

@interface NESConnectionManager : NSObject <SocketIODelegate> {
    NSURL *serverURL;
    NSUUID *uuid;
    SocketIO *socket;
    NSMutableArray *workQueue;
    NESConnectionManagerRequest *currentRequest;
    BOOL requestDisconnect;
    NSTimer *reconnectTimer;
    NSString *registrationToken;
    BOOL newClient;
    BOOL rebuild;
    NSDictionary *clientInfo;
}

@property (strong) NESConnections *connections;
@property (strong, nonatomic, setter=setAppConfig:) NESAppConfig *appConfig;
@property (strong, readonly) NSString *instanceName;
@property (atomic) BOOL connected;
@property (nonatomic, setter=setRegistered:) BOOL registered;
@property (nonatomic, setter=setRunning:) BOOL running;
@property (atomic) BOOL error;
@property (atomic) NESConnectionManagerErrorCodeType errorCode;
@property (strong, readonly) NSString *errorMessage;
@property (atomic) BOOL reconnecting;
@property (atomic) BOOL reconnectOnDisconnect;

-(NESConnectionManager *) initWithConnections: (NESConnections *)rootConnections;
-(BOOL) isConnected;
-(BOOL) isRegistered;
-(BOOL) isRunning;
-(void) start;
-(void) stop;
-(void) run;
-(void) update;
-(void) registerClient:(NSMutableDictionary *)credentials;
-(void) sendCommand:(NSString *)command withData:(id)data andCallback:(void(^)(BOOL success, id data))callback;

@end

typedef enum {
    NESMR_QUEUED       = 0,
    NESMR_PROCESSING   = 1,
    NESMR_COMPLETED    = 2,
    NESMR_FAILED       = 3
} NESConnectionManagerRequestState;


@interface NESConnectionManagerRequest : NSObject

@property (strong) NSString *command;
@property (atomic) id data;
@property (atomic) NESConnectionManagerRequestState state;
@property (strong) void(^callback)(BOOL success, id data);

@end