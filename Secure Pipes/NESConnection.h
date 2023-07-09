//
//  NESConnection.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/15/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,NESConnectionType) {
    NESConnectionLocalForward = 1,
    NESConnectionRemoteForward = 2,
    NESConnectionProxy = 3,
    NESConnectionSSH = 4,
    NESConnectionX11 = 5,
    NESConnectionManaged = 6,
    NESConnectionManagedLocalForward = 7,
    NESConnectionManagedRemoteForward = 8,
    NESConnectionManagedProxy = 9,
    NESConnectionContainer = 100
};

typedef NS_ENUM(NSInteger, NESConnectionStatus) {
    
    // These are the actual connection status states
    NESConnectionIdle = 1 << 0,
    NESConnectionConnecting = 1 << 1,
    NESConnectionConnected = 1 << 2,
    NESConnectionError = 1 << 3,
    NESConnectionAuthenticationFailed = 1 << 4,
    NESConnectionUnknownKey = 1 << 5,
    NESConnectionKeyChanged = 1 << 6,
    NESConnectionInvalid = 1 << 7,
    NESConnectionInfoReceived = 1 << 8,
    
    // These are the managed connection sync states
    NESConnectionGeneralConfigChanged = 1 << 16,
    NESConnectionConfigInvalidated = 1 << 17,
    NESConnectionUpdatingConfig = 1 << 18,
    NESConnectionSyncFailure = 1 << 19,
    NESConnectionSyncOk = 1 << 20,
    NESConnectionNetworkConfigChanged = 1 << 21,
    NESConnectionConfigRevalidated = 1 << 22,
    NESConnectionSyncConflict = 1 << 23
};

#define CONNECTION_STATE_MASK ((1<<16)-1)
#define BONJOUR_DEFAULT_TXT_DICT @{@"txtvers" : @"1"}

@class NESConnectionProcess;

#define LOCAL_FORWARD_CONTAINER_NAME @"Local Forwards"
#define REMOTE_FORWARD_CONTAINER_NAME @"Remote Forwards"
#define PROXY_CONTAINER_NAME @"SOCKS Proxies"
#define SSH_CONTAINER_NAME @"SSH Connections"
#define X11_CONTAINER_NAME @"X11 Connections"
#define MANAGED_PROXY_CONTAINER_NAME @"Managed SOCKS Proxies"
#define MANAGED_LOCAL_FORWARD_CONTAINER_NAME @"Managed Local Forward"
#define MANAGED_REMOTE_FORWARD_CONTAINER_NAME @"Managed Remote Forward"

#define PREFS_DIR @"~/Library/Preferences"
#define SUPPORT_DIR @"~/Library/Application Support/Secure Pipes"
#define PREFS_FILE @"net.edgeservices.connections.plist"
#define PREFS_FULL_PATH PREFS_DIR @"/" PREFS_FILE

@interface NESConnection : NSObject {
    NSRecursiveLock *statusLock;
    BOOL bonjourPublished;
    NSData *bonjourTXTRecord;
}

@property(strong) NSString *name;
@property(strong) NSMutableArray *children;
@property(weak) NESConnection *parent;
@property (assign) NSInteger type;
@property(strong) NSMutableDictionary *connectionConfig;
@property(strong) NSMutableDictionary *connectionStatus;
@property (assign,getter = status,setter = setStatus:) NESConnectionStatus status;
@property (strong,setter = setConnectionProcess:,nonatomic) NESConnectionProcess *connectionProcess;
@property (strong) NSDate *lastStartTime;
@property (assign) BOOL reconnecting;
@property (strong) NSTimer *reconnectTimer;
@property (strong) NSNetService *bonjourService;

- (id)initWithName: (NSString *) name asType: (NSInteger) conType;
- (id)initWithName: (NSString *) name asType: (NSInteger) conType andConfig:(NSDictionary *) config;
- (NSString *) verboseDescription: (BOOL) longVersion;
- (NSInteger) addConnection: (NESConnection *)connection;
- (NSIndexSet *) removeConnection: (NESConnection *)connection;
- (NSArray *) updateConnection:(NSString *)name withNewConnection:(NESConnection *) newConnection;
- (id)configForKey: (NSString *)key;
- (void) setConfigForKey: (NSString *)key value:(NSObject *)value;
- (id)statusForKey: (NSString *)key;
- (void) setStatusForKey: (NSString *)key value:(NSString *)value;
- (void) setStatusWithUpdate:(NSDictionary *) update;
- (void) queueStatusUpdate:(NESConnectionStatus)newStatus withData:(NSString *)data;
- (void) queueStatusUpdate:(NESConnectionStatus)newStatus withData:(NSString *)data andArgs:(NSString *)args;
- (NSDictionary *) dequeueStatusUpdate;
- (void) setConnectionProcess:(NESConnectionProcess *)connectionProcess;
- (void) publishBonjourService;
- (void) stopBonjourService;
- (void) resetBonjourTXTData:(NSMutableDictionary *)txtDict withSubType:(NSString *)subType;
- (void) startConnection;
- (BOOL) stopConnectionSynchronous;
- (BOOL) stopConnection;
- (NSMutableArray *) findConnectionsWithStatus:(NESConnectionStatus)status;
- (BOOL) needsAdministratorRights;
- (BOOL) needsSavedAdministratorPasswd;
- (BOOL) isManaged;
- (BOOL) isActive;

+ (NSUInteger) indexForInserting:(NESConnection *)conn inArray:(NSArray *)array;
+ (BOOL) isValidIP:(NSString *) ipAddress;
+ (BOOL) isValidHost:(NSString *) host;
+ (BOOL) isValidPort:(NSString *) host;
+ (NSMutableDictionary *) defaultConfigForType:(NSInteger)type;
+ (NSImage *) imageForStatus:(NESConnectionStatus) status;
+ (NSString *)nameforType:(NESConnectionType)type;
+ (void) removeKnownHostFile:(NESConnection *) connection;
+ (void) removeSSHConfigFile:(NESConnection *) connection;
+ (NSString *)generateConnectionUUID;


@end

@interface NESConnections : NESConnection {
@private
    NSMutableArray *rootContainers;
    NSDictionary *containerNames;
}

@property (atomic) NSMutableArray *statusUpdates;
@property (atomic) NSMutableArray *stoppedConnections;
@property (atomic) BOOL configUpdated;
@property (atomic) BOOL statusHasUpdate;
@property (atomic) BOOL statusUpdated;

- (NESConnection *) getHasStatusUpdateConnection;

- (NSIndexSet *) addConnection:(NESConnection *) connection;
- (NSIndexSet *) removeConnection: (NESConnection *)connection;
- (NSArray *) updateConnection:(NESConnection *)connection forName:(NSString *)name;
- (NSIndexSet *) indexForConnectionTypeContainer:(NSInteger) type;
- (NSIndexSet *) addContainerForConnectionType:(NSInteger) type;
- (NESConnection *) getConnectionByName: (NSString *) name forConnectionType:(NSInteger) type;
- (BOOL) checkDuplicateName: (NSString *) name forConnectionType:(NSInteger) type;
- (BOOL) loadConnections;
- (BOOL) saveConnections;
- (void) restartStoppedConnections;
- (void) fastStopActiveConnections;
- (void) stopActiveConnections;
- (void) startOnLaunchConnections;
- (NSMutableArray *) getStartOnLaunchConnections;
- (NSMutableArray *) findConnectionsWithStatus:(NESConnectionStatus)status;
- (NESConnection *) findConnectionWithUUID:(NSString *)UUID;
- (BOOL) hasManagedConnections;
- (BOOL) hasUnManagedConnections;
- (NSMutableArray *) getManagedConnections;
- (void) checkManagedConnectionsForUpdates: (void (^)(NSMutableDictionary *config))completionHandler;
- (BOOL) hasActiveConnections;

// Temporary
-(NSDictionary *) connectionsToDictionary;

@end