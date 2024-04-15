//
//  NESConnection.m
//  Secure Pipes
//
//  Created by Timothy Stonis and Tennyson Stonis on 1/15/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnection.h"
#import "NESManagedConnection.h"
#import "NESKeychain.h"
#import "NESConnectionProcess.h"
#import "NESGetScriptOutput.h"

@implementation NESConnection

- (id)initWithName: (NSString *) name asType: (NSInteger) conType {
    
    self = [super init];
    
    if (self) {
        _name = name;
        _children = nil;
        _type = conType;
        _parent = nil;
        _connectionConfig = nil;
        _connectionStatus = [[NSMutableDictionary alloc] init];
        [_connectionStatus setObject:[[NSMutableArray alloc] init] forKey:@"statusMessages"];
        [_connectionStatus setObject:@(NESConnectionIdle) forKey:@"currentStatus"];
        _connectionProcess = [[NESConnectionProcess alloc] initWithConnection:self];
        _lastStartTime = nil;
        _reconnecting = NO;
        statusLock = [[NSRecursiveLock alloc] init];
    }
    
    return self;
}

- (NSMutableArray *) findConnectionsWithStatus:(NESConnectionStatus)status {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (NESConnection *connection in [self children]) {
        if (connection.status&status) {
            [result addObject:connection];
        }
    }
    return result;
}

- (NESConnection *) findConnectionWithName:(NSString *) name {
    
    for (NESConnection *child in _children) {
        if ([[child name] isEqualToString: name]) {
            return child;
        }
    }
    
    return nil;
}

- (NESConnection *) findConnectionWithUUID:(NSString *) UUID {
    
    for (NESConnection *child in _children) {
        if ([[child configForKey:@"UUID"] isEqualToString: UUID]) {
            return child;
        }
    }
    
    return nil;
}

- (BOOL) isActive {

    if (([self status]&NESConnectionConnected)||([self status]&NESConnectionConnecting)) {
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL) isManaged {
    
    return [[_connectionConfig objectForKey:@"managedConnection"] boolValue];
    
    switch (_type) {
        case NESConnectionManagedProxy:
        case NESConnectionManagedLocalForward:
        case NESConnectionManagedRemoteForward:
            return YES;
            break;
        default:
            return NO;
            break;
    }
    
}



+ (NSString *)generateConnectionUUID {
    
    return [[NSUUID UUID] UUIDString];
    
}

- (id)initWithName: (NSString *) name asType: (NSInteger) conType andConfig:(NSDictionary *) config {

    self = [self initWithName:name asType:conType];
    
    if (self) {
        if (config != nil) {
            _connectionConfig = [[NSMutableDictionary alloc] initWithDictionary: config];
            if ((![_connectionConfig objectForKey:@"UUID"]) && (conType != NESConnectionContainer)) {
                [_connectionConfig setObject:[NESConnection generateConnectionUUID] forKey:@"UUID"];
            }
            
            // Fill in defaults for any config that might be missing.
            NSDictionary *defaultConfig = [NESConnection defaultConfigForType:[self type]];
            for (NSString *key in [NESConnection defaultConfigForType:[self type]]) {
                if ([_connectionConfig valueForKey:key] == nil) {
                    [_connectionConfig setObject:[defaultConfig valueForKey:key] forKey:key];
                }
            }
                        
            if (conType == NESConnectionManaged) {
                NSString *managedType = [_connectionConfig objectForKey:@"managedType"];
                if ([managedType isEqualToString:@"SOCKS Proxy"] ) {
                    _type = NESConnectionManagedProxy;
                } else if ([managedType isEqualToString:@"Remote Forward"]) {
                    _type = NESConnectionManagedRemoteForward;
                } else {
                    _type = NESConnectionManagedLocalForward;
                }
            }
            
            if ([[_connectionConfig objectForKey:@"useBonjour"] boolValue] == YES) {
                int port = (int)[[_connectionConfig objectForKey:@"localBindPort"] integerValue];
                NSString *service = [NSString stringWithFormat:@"_%@._tcp",(NSString *)[_connectionConfig objectForKey:@"bonjourServiceName"]];
                _bonjourService = [[NSNetService alloc] initWithDomain:@"" type:service name:name port:port];
                [_bonjourService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:BONJOUR_DEFAULT_TXT_DICT]];
                bonjourPublished = NO;
            }
            
        }
    }
    
    return self;
    
}

- (NSDictionary *) asDictionary {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setValue:[NSNumber numberWithLong:[self type]] forKey:@"type"];
    NSMutableDictionary *configCopy = [[NSMutableDictionary alloc] initWithDictionary:_connectionConfig];
    // Don't save any passwords to disk (this should probably be dynamic, but only 2 right now...
    [configCopy removeObjectForKey:@"sshPassword"];
    [configCopy removeObjectForKey:@"httpProxyPassword"];
    [dict setValue:configCopy forKey:@"config"];

    if (_children != nil) {
        NSMutableDictionary *childrenDict = [[NSMutableDictionary alloc] init];
        // Make a dictionary of each child...
        for (id child in _children) {
            [childrenDict setObject:[child asDictionary] forKey:[child name]];
        }
        [dict setObject:childrenDict forKey:@"children"];
    }
    
    return dict;
}

- (NESConnection *) fromDictionary:(NSDictionary *) dict withName:(NSString *)name {
    
    NSInteger type = [(NSNumber *)[dict objectForKey:@"type"] integerValue];
    NSDictionary *config = [dict objectForKey:@"config"];
    NESConnection *conn;
    
    if ([[config objectForKey:@"managedConnection"] boolValue] == true) {
        conn = [[NESManagedConnection alloc] initWithName:name asType:type andConfig:config];
    } else {
        conn = [[NESConnection alloc] initWithName:name asType:type andConfig:config];
    }
    
    NSString *keyChainPassword = [NESKeychain getPassword:name andType:type];
    if (keyChainPassword)
        [conn setConfigForKey:@"sshPassword" value:keyChainPassword];

    // TODO: This really needs to be encapsulated... but feeling lazy
    keyChainPassword = [NESKeychain getPassword:[name stringByAppendingString:@" httpProxy"] andType:type];
    if (keyChainPassword)
        [conn setConfigForKey:@"httpProxyPassword" value:keyChainPassword];

    
    
    NSDictionary *dictChildren = [dict objectForKey:@"children"];
    if ( dictChildren != nil) {
        for (id child in dictChildren) {
            NESConnection *newChild = [self fromDictionary:[dictChildren objectForKey:child] withName:child];
            [conn addConnection:newChild];
        }
    }
    
    return conn;
}

- (BOOL) isContainer {
    return (_type == NESConnectionContainer);
}

- (BOOL) needsSavedAdministratorPasswd {

    switch (_type) {
            case NESConnectionProxy:
            if ([[self configForKey:@"autoConfigProxy"] boolValue] == YES) {
                return NO;
            }
            break;
    }
    
    return NO;
    
}

- (BOOL)needsAdministratorRights {
    
    switch (_type) {
        case NESConnectionProxy:
        case NESConnectionManagedProxy:
            if ([[self configForKey:@"autoConfigProxy"] boolValue] == YES) {
                return YES;
            }
        case NESConnectionLocalForward:
            if ([[self configForKey:@"localBindPort"] integerValue] < 1024) {
                return YES;
            }
            break;
    }
            
    return NO;
}

+ (NSUInteger) indexForInserting:(NESConnection *)conn inArray:(NSArray *)array {

    int i = 0, limit = (int)[array count];
    
    if ([conn isContainer]) {

        while (i<[array count]) {
            if ([[[array objectAtIndex:i] name] hasPrefix:@"Managed"]) {
                break;
            } else {
                i++;
            }
        }
        
        if ([[conn name] hasPrefix:@"Managed"]) {
            limit = (int)[array count];
        } else {
            limit = i;
            i=0;
        }
    }
    
    for (;i<limit;i++) {
        if ([[conn name] compare:[[array objectAtIndex:i] name] options:NSCaseInsensitiveSearch ] == NSOrderedDescending)
            continue;
        else
            break;
    }
    
    return i;
}

- (void) writeSSHConfig: (NESConnection *)connection {
    
    NSString *configFile = [[NSString alloc] init];
    
    // First the generic item
    
    NSString *bindToDevice = [connection configForKey:@"bindToDevice"];
    NSRange range = [bindToDevice rangeOfString:@"("];
    if (range.location != NSNotFound) {
        NSUInteger start = range.location + 1;
        NSRange endRange = [bindToDevice rangeOfString:@")" options:0 range:NSMakeRange(start, bindToDevice.length - start)];
        if (endRange.location != NSNotFound) {
            NSUInteger length = endRange.location - start;
            NSString *extractedString = [bindToDevice substringWithRange:NSMakeRange(start, length)];
            if (bindToDevice && ![bindToDevice isEqualToString:@"No"]) {
                configFile = [configFile stringByAppendingFormat:@"BindInterface %@\r\n", extractedString];
            }
        }
    }

    configFile = [configFile stringByAppendingFormat:@"Host %@\r\n",[connection configForKey:@"UUID"]];
    configFile = [configFile stringByAppendingFormat:@"HostName %@\r\n",[connection configForKey:@"sshServer"]];
    configFile = [configFile stringByAppendingFormat:@"Port %@\r\n",[connection configForKey:@"sshPort"]];
    configFile = [configFile stringByAppendingFormat:@"HostKeyAlias %@\r\n",[connection configForKey:@"UUID"]];
    configFile = [configFile stringByAppendingFormat:@"User %@\r\n",[connection configForKey:@"sshUsername"]];
    configFile = [configFile stringByAppendingFormat:@"PermitLocalCommand %@\r\n",@"yes"];
    configFile = [configFile stringByAppendingFormat:@"ServerAliveInterval %@\r\n",[connection configForKey:@"sshServerAliveInterval"]];
    configFile = [configFile stringByAppendingFormat:@"ServerAliveCountMax %@\r\n",[connection configForKey:@"sshServerAliveCountMax"]];
    
    // Static config options.
    configFile = [configFile stringByAppendingFormat:@"LocalCommand %@\r\n",@"echo Connected"];
    configFile = [configFile stringByAppendingFormat:@"NumberOfPasswordPrompts %@\r\n",@"1"];
    configFile = [configFile stringByAppendingFormat:@"ConnectTimeout %@\r\n",@"10"];
    
    configFile = [configFile stringByAppendingFormat:@"Compression %@\r\n",[[connection configForKey:@"compressData"] intValue]==YES?@"yes":@"no"];
    configFile = [configFile stringByAppendingFormat:@"StrictHostKeyChecking %@\r\n",[[connection configForKey:@"strictHostKeys"] intValue]==YES?@"ask":@"no"];
    
    if ([[connection configForKey:@"useCustomIdentity"] intValue] == YES) {
        configFile = [configFile stringByAppendingFormat:@"PreferredAuthentications %@\r\n",@"\"publickey,keyboard-interactive\""];
        configFile = [configFile stringByAppendingFormat:@"IdentityFile \"%@\"\r\n",[connection configForKey:@"sshIdentityFile"]];
    } else {
        configFile = [configFile stringByAppendingFormat:@"PreferredAuthentications %@\r\n",@"keyboard-interactive,password"];        
    }

    if ([[connection configForKey:@"useHTTPProxy"] intValue] == YES) {
        NSString *corkPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/corkscrew"];
        configFile = [configFile stringByAppendingFormat:@"ProxyCommand \"%@\" %@ %@ %%h %%p\r\n",
                      corkPath,[connection configForKey:@"httpProxyHost"],[connection configForKey:@"httpProxyPort"]];
    }
    
    
    switch ([connection type]) {
        case NESConnectionLocalForward:
            configFile = [configFile stringByAppendingFormat:@"LocalForward %@:%@ %@:%@\r\n",[connection configForKey:@"localBindAddress"],[connection configForKey:@"localBindPort"],[connection configForKey:@"remoteHost"],[connection configForKey:@"remotePort"]];
            break;
            
        case NESConnectionRemoteForward:
            configFile = [configFile stringByAppendingFormat:@"RemoteForward %@:%@ %@:%@\r\n",[connection configForKey:@"remoteBindAddress"],[connection configForKey:@"remoteBindPort"],[connection configForKey:@"localHost"],[connection configForKey:@"localHostPort"]];
            break;
            
        case NESConnectionProxy:
        case NESConnectionManagedProxy:
            configFile = [configFile stringByAppendingFormat:@"DynamicForward %@:%@\r\n",[connection configForKey:@"localBindAddress"],[connection configForKey:@"localBindPort"]];
            break;
            
        default:
            break;
    }
    
    NSString *knownHostsFile = [[NSString alloc] initWithFormat:@"%@/%@.known_hosts",SUPPORT_DIR,[connection configForKey:@"UUID"]];
    knownHostsFile = [knownHostsFile stringByExpandingTildeInPath];
    configFile = [configFile stringByAppendingFormat:@"UserKnownHostsFile \"%@\"\r\n",knownHostsFile];

    // This should be the last thing we write to the file
    if ([[connection configForKey:@"addSSHOptions"] boolValue] == YES) {
        configFile = [configFile stringByAppendingFormat:@"# Additional options added by user:\r\n%@",[connection configForKey:@"customSSHOptions"]];
    }
    
    NSString *filename = [[NSString alloc] initWithFormat:@"%@/%@.ssh_config",SUPPORT_DIR,[connection configForKey:@"UUID"]];
    filename = [filename stringByExpandingTildeInPath];
    NSError *error;
    if (![configFile writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"Error writing config file: %ld",[error code]);
    }
    
}

- (void) addKeyChainPassword: (NESConnection *)connection withPrefix: (NSString *) prefix {

    NSString *passKey = [NSString stringWithFormat:@"%@Password",prefix];
    NSString *userKey = [NSString stringWithFormat:@"%@Username",prefix];
    NSString *keyName = [prefix isEqualToString:@"ssh"]?[connection name]:[NSString stringWithFormat:@"%@ %@",[connection name],prefix];
    
    NSString *passwd = [[connection connectionConfig] valueForKey:passKey] ;
    if ((!passwd)||[passwd isEqualToString:@""]) {
        [NESKeychain removeKeyChainItem:keyName andType:[connection type]];
    } else {
        // If the Keychain item exists, it's because we're building up the connection list from disk.
        if (![NESKeychain keyChainItemExists:keyName withType:[connection type]]) {
            BOOL okay;
            okay = [NESKeychain addKeyChainItem:keyName withUser:[connection configForKey:userKey]
                                    andPassword:passwd andType:[connection type]];
            if (!okay)
                NSLog(@"ERROR: Failed to add password for %@ to keychain",[connection name]);
        }
    }
    
}

- (NSInteger) addConnection: (NESConnection *)connection {
    
    if (_children == nil)
        _children = [[NSMutableArray alloc] init];
    
    NSUInteger index = [NESConnection indexForInserting:connection inArray:_children];
    [_children insertObject:connection atIndex:index];
    [connection setParent:self];
    
    [self addKeyChainPassword:connection withPrefix:@"ssh"];
    [self addKeyChainPassword:connection withPrefix:@"httpProxy"];
    
    [self writeSSHConfig:connection];
    
    return [_children indexOfObject:connection];
}

- (NSDictionary *) dequeueStatusUpdate {
    
    [statusLock lock];
    NSMutableArray *statusMessages = [[self connectionStatus] objectForKey:@"statusMessages"];
    if ( [statusMessages count] == 0) {
        NSLog(@"ERROR: dequeuing non-existent messsage");
        [statusLock unlock];
        return nil;
    }
    NSDictionary *update = [statusMessages objectAtIndex:0];
    [statusMessages removeObjectAtIndex:0];

    [statusLock unlock];
    
    return update;
}

- (void) queueStatusUpdate:(NESConnectionStatus)newStatus withData:(NSString *)data andArgs: (NSString *)args {

    [statusLock lock];

    if ([self type] != NESConnectionContainer) {
        NSMutableArray *statusMessages = [[self connectionStatus] objectForKey:@"statusMessages"];
        NSDictionary *message = @{@"status" : @(newStatus), @"timestamp": [[NSDate date] description], @"data" : (data)?data:@"", @"args" : (args)?args:@"" };
        [statusMessages addObject:message];
        [[self connectionStatus] setObject:statusMessages forKey:@"statusMessages"];
    }

    [statusLock unlock];
    
}

- (void) queueStatusUpdate:(NESConnectionStatus)newStatus withData:(NSString *)data {
    
    [self queueStatusUpdate:newStatus withData:data andArgs:nil];
    
}

- (void) testTimer:(NSTimer *) timer {
    NESConnection *connection = [timer userInfo];
    
    NSLog(@"Timer fired...");
    if ([connection type] != NESConnectionContainer) {
        NSMutableArray *statusMessages = [[connection connectionStatus] objectForKey:@"statusMessages"];
        NSDictionary *message = @{@"status" : @(rand()%3), @"timestamp": [[NSDate date] description] };
        [statusMessages addObject:message];
        [[connection connectionStatus] setObject:statusMessages forKey:@"statusMessages"];
    }
    
}

+ (void) removeKnownHostFile:(NESConnection *) connection {

    // Remove config and known_hosts files for the connection
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *knownHostsFile = [[NSString alloc] initWithFormat:@"%@/%@.known_hosts",SUPPORT_DIR,[connection configForKey:@"UUID"]];
    knownHostsFile = [knownHostsFile stringByExpandingTildeInPath];
    [fileManager removeItemAtPath:knownHostsFile error:nil];
    
}

+ (void) removeSSHConfigFile:(NESConnection *) connection {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filename = [[NSString alloc] initWithFormat:@"%@/%@.ssh_config",SUPPORT_DIR,[connection configForKey:@"UUID"]];
    filename = [filename stringByExpandingTildeInPath];
    [fileManager removeItemAtPath:filename error:nil];
    
}

+ (void) removeLogFile:(NESConnection *) connection {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filename = [[NSString alloc] initWithFormat:@"%@/%@.log",SUPPORT_DIR,[connection configForKey:@"UUID"]];
    filename = [filename stringByExpandingTildeInPath];
    [fileManager removeItemAtPath:filename error:nil];
    
}

- (NSIndexSet *) removeConnection:(NESConnection *)connection {
    
    // Remove the Keychain items
    [NESKeychain removeKeyChainItem:[connection name] andType:[connection type]];
    [NESKeychain removeKeyChainItem:[[connection name] stringByAppendingString:@" httpProxy"] andType:[connection type]];
    
    // Remove config and known_hosts files for the connection
    [NESConnection removeKnownHostFile:connection];
    [NESConnection removeSSHConfigFile:connection];
    [NESConnection removeLogFile:connection];
    
    NSIndexSet *index = [[NSIndexSet alloc] initWithIndex:[_children indexOfObject:connection]];
    [_children removeObject:connection];
    
    return index;
}

- (NSArray *) updateConnection:(NSString *)name withNewConnection:(NESConnection *) newConnection {
    
    // Find the index of the current one...
    NESConnection *currentConnection = [self findConnectionWithName:name];
    NSMutableArray *moveSet = [[NSMutableArray alloc] init];
    
    [moveSet addObject:[[NSIndexSet alloc] initWithIndex:[_children indexOfObject:currentConnection]]];

    // Stop any potential reconnects on this.
    if ([currentConnection reconnectTimer]) {
        [[currentConnection reconnectTimer] invalidate];
    }
    
    // Remove the known_hosts if we make changes
    if ([[currentConnection configForKey:@"strictHostKeys"] boolValue] != [[newConnection configForKey:@"strictHostKeys"] boolValue] ) {
        [NESConnection removeKnownHostFile:currentConnection];
    }
    
    // Remove the Keychain item
    [NESKeychain removeKeyChainItem:[currentConnection name] andType:[currentConnection type]];
    [NESKeychain removeKeyChainItem:[[currentConnection name] stringByAppendingString:@" httpProxy"] andType:[currentConnection type]];

    // Copy the old connection's status and process
    [newConnection setConnectionStatus:[currentConnection connectionStatus]];
    [newConnection setConnectionProcess:[currentConnection connectionProcess]];

    [_children removeObject:currentConnection];
    
    // Increase the revision value if modified by the client, but not if an update from the server
    NSTimeInterval currentEpochTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [newConnection setConfigForKey:@"revisionTime" value:[NSNumber numberWithDouble:currentEpochTime]];

    [moveSet addObject:[[NSIndexSet alloc] initWithIndex:[self addConnection:newConnection]]];
    
    return moveSet;
    
}
    
- (NSString *) verboseDescription: (BOOL) longVersion {
    NSString *formatString;
    
    switch ([self type]) {
        case NESConnectionLocalForward:
        case NESConnectionManagedLocalForward:
            formatString = @"Local bind %@:%@ forwards to %@:%@ via %@:%@";
        
        return [NSString stringWithFormat:formatString,[self configForKey:@"localBindAddress"],[self configForKey:@"localBindPort"], [self configForKey:@"remoteHost"], [self configForKey:@"remotePort"],[self configForKey:@"sshServer"],[self configForKey:@"sshPort"]];
        break;
        case NESConnectionRemoteForward:
        case NESConnectionManagedRemoteForward:
            formatString = @"Remote bind %@:%@ on %@:%@ forwards to %@:%@";
            
            return [NSString stringWithFormat:formatString,[self configForKey:@"remoteBindAddress"],
                    [self configForKey:@"remoteBindPort"],[self configForKey:@"sshServer"],
                    [self configForKey:@"sshPort"],[self configForKey:@"localHost"],
                    [self configForKey:@"localHostPort"]];
        case NESConnectionProxy:
        case NESConnectionManagedProxy:
            if ([self status]&NESConnectionInvalid) {
                return @"This connection's ticket is no longer valid.";
            }
            formatString = @"Local bind %@:%@ proxys through %@:%@";
            
            return [NSString stringWithFormat:formatString,[self configForKey:@"localBindAddress"],
                    [self configForKey:@"localBindPort"],[self configForKey:@"sshServer"],
                    [self configForKey:@"sshPort"]];
        default:
        break;
    }
    
    return [self name];
}

+ (NSString *)nameforType:(NESConnectionType)type {
    
    switch (type) {
        case NESConnectionLocalForward:
        case NESConnectionManagedLocalForward:
            return @"Local Forward";
        case NESConnectionRemoteForward:
        case NESConnectionManagedRemoteForward:
            return @"Remote Forward";
        case NESConnectionProxy:
        case NESConnectionManagedProxy:
            return @"SOCKS Proxy";
        default:
            return @"Unknown";
            break;
    }
}

- (void) setStatusForKey: (NSString *)key value:(NSString *)value {
    
    if (_connectionStatus) {
        value?[_connectionStatus setObject:value forKey:key]:[_connectionStatus removeObjectForKey:key];
    }
    
}

- (id)statusForKey: (NSString *)key {
    
    if (_connectionStatus) {
        return [_connectionStatus valueForKey:key];
    } else
        return nil;
    
}

- (void) setStatusWithUpdate:(NSDictionary *) update {
    NESConnectionStatus newStatus = [(NSString *)[update objectForKey:@"status"] integerValue];

    [self setStatus:newStatus];
    
    // This is a bit of a hack
    if (newStatus&CONNECTION_STATE_MASK) {
        [self setStatusForKey:@"message" value:[update objectForKey:@"data"]];
    } else {
        [self setStatusForKey:@"syncMessage" value:[update objectForKey:@"data"]];
    }
    
}

- (void) setConfigForKey: (NSString *)key value:(NSObject *)value {
    
    if (_connectionConfig) {
        value?[_connectionConfig setObject:value forKey:key]:[_connectionConfig removeObjectForKey:key];
    }
    
}

- (id)configForKey: (NSString *)key {
    
    if (_connectionConfig) {
        
        if ([_connectionConfig valueForKey:key] == nil)
           NSLog(@"WARNING: nil value for config key %@",key);
        
        if ([key isEqualToString:@"sshPassword"])
            return [NESKeychain getPassword:[self name] andType:[self type]]?:@"";
        else if ([key isEqualToString:@"httpProxyPassword"])
            return [NESKeychain getPassword:[[self name] stringByAppendingString:@" httpProxy"] andType:[self type]]?:@"";
        else
            return [_connectionConfig valueForKey:key];
    } else {
        NSLog(@"ERROR: No connection config set.");
        return nil;
    }
    
}

+ (BOOL) isValidPort:(NSString *) port {
    NSString *validPortRegex = @"^([1-9]|[1-9][0-9]|[1-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9][0-9])$";
    NSError *error = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:validPortRegex options:NSRegularExpressionCaseInsensitive error:&error];
    
    if ([regex numberOfMatchesInString:port options:0 range:NSMakeRange(0, [port length])] > 0) {
        if ([port integerValue] > 65535)
            return NO;
        else
            return YES;
    }
    
    return NO;
}


+ (BOOL) isValidIP:(NSString *) ipAddress {
    NSString *validIpAddressRegex = @"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$";
    NSError *error = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:validIpAddressRegex options:NSRegularExpressionCaseInsensitive error:&error];
    
    if ([regex numberOfMatchesInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])] > 0)
        return YES;
    else
        return NO;
}

+ (BOOL) isValidHost:(NSString *) host {
    NSString *validHostnameRegex = @"^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$";
    NSError *error = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:validHostnameRegex options:NSRegularExpressionCaseInsensitive error:&error];
    
    if ([regex numberOfMatchesInString:host options:0 range:NSMakeRange(0, [host length])] > 0) {
        return YES;
    } else
        return NO;
}

+ (NSMutableDictionary *) defaultConfigForType:(NSInteger)type {
    NSMutableDictionary *config = [[NSMutableDictionary alloc] initWithDictionary:
                                   @{@"includeInMenu" : @true, @"startOnLaunch" : @false,
                                     @"autoReconnect" : @false, @"compressData" : @false,
                                     @"strictHostKeys" : @true, @"reconnectInterval" : @30,
                                     @"useCustomIdentity" : @false, @"sshServerAliveCountMax" : @5,
                                     @"sshServerAliveInterval" : @30, @"useHTTPProxy" : @false,
                                     @"httpProxyNeedsPassword" : @false,
                                     @"useScriptForHostname" : @false, 
                                     // Managed connection related config
                                     @"managedConnection" : @false,
                                     @"dirty" : @true
                                      }
                                   ];
    
    // Maybe convert this to a case statement some day...
    if (type == NESConnectionProxy) {
        [config setObject:@false forKey:@"autoConfigProxy"];
    } else if (type == NESConnectionManaged) {
        [config setObject:@true forKey:@"managedConnection"];
    }
    
    
    return config;
}

- (void) setStatus:(NESConnectionStatus) status {
    NESConnectionStatus currentStatus = [[[self connectionStatus] objectForKey:@"currentStatus"] integerValue];
    
    // Check if this is a connection status update or a sync
    if (status&CONNECTION_STATE_MASK) {
        status = (currentStatus&~CONNECTION_STATE_MASK)|status;
    } else {
        status = (currentStatus&CONNECTION_STATE_MASK)|status;
    }

    return [[self connectionStatus] setObject:@(status) forKey:@"currentStatus"];

}

- (NESConnectionStatus) status {
    
    return [(NSString *)[[self connectionStatus] objectForKey:@"currentStatus"] integerValue];
    
}

+ (NSImage *) imageForStatus:(NESConnectionStatus) status {

    NSImage *image;
    
    switch (status&CONNECTION_STATE_MASK) {
        case NESConnectionIdle:
            return [NSImage imageNamed:NSImageNameStatusNone];
            break;
        case NESConnectionConnected:
            return [NSImage imageNamed:NSImageNameStatusAvailable];
            break;
        case NESConnectionConnecting:
            return [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            break;
        case NESConnectionError:
        case NESConnectionAuthenticationFailed:
            return [NSImage imageNamed:NSImageNameStatusUnavailable];
            break;
        case NESConnectionInvalid:
            image = [NSImage imageNamed:NSImageNameStopProgressTemplate];
            [image setTemplate:NO];
            return image;
            break;
        default:
            return [NSImage imageNamed:NSImageNameStopProgressTemplate];
;
            break;
    }
}

- (void) setConnectionProcess:(NESConnectionProcess *)connectionProcess; {
    _connectionProcess = connectionProcess;
    [connectionProcess setConnection:self];
}

- (void) startConnection {
    _lastStartTime = [NSDate date];
    
    if ([[self configForKey:@"useScriptForHostname"] integerValue] == YES) {
        NESGetScriptOutput *testRun = [[NESGetScriptOutput alloc] initWithScript:[self configForKey:@"hostnameScriptFile"]];
        [testRun setConnection:self];
        __block NSString *address, *error = nil;
        
        if ((![testRun scriptExists]) || (![testRun scriptIsExecutable])) {
            error = @"The specified script file no longer exists. Please select a new file.";
            
        }
        
        // Looks like we have one and it's executable - let's try to run it.
        [testRun runWithCompletionHandler:^(NSString *output) {
            
            // Cut the output if illegal
            if ([output length] > _POSIX_HOST_NAME_MAX) {
                [output substringToIndex:(_POSIX_HOST_NAME_MAX-1)];
            }
            
            if (!([NESConnection isValidHost:output]||[NESConnection isValidIP:output])) {
                error = [NSString stringWithFormat:NSLocalizedString(@"The specified SSH server hostname script did not return a valid hostname or IP address. The returned value was:\n\n %@", nil),output];
            }
            
            address = output;
        }];
        
        if (error) {
            [self queueStatusUpdate:NESConnectionError withData:error];
            return;
        } else {
            if ((![((NSString *)[self configForKey:@"sshServer"]) isEqualToString:address]) &&
                ([[self configForKey:@"strictHostKeys"] intValue] == NO)) {
                [NESConnection removeKnownHostFile:self];
            }
            [self setConfigForKey:@"sshServer" value:address];
            [self writeSSHConfig:self];
        }
        
    }
    
    [_connectionProcess performSelectorOnMainThread:@selector(startConnection) withObject:nil waitUntilDone:NO];
        
}

- (void) resetBonjourTXTData:(NSMutableDictionary *)txtDict withSubType:(NSString *)subType {
    
    if (txtDict) {
        
        [self stopBonjourService];
        _bonjourService = nil;
        NSLog(@"TXT: %@",txtDict);
        NSLog(@"Subtype: %@",subType);
        // Make a new service
        bonjourTXTRecord = [NSNetService dataFromTXTRecordDictionary:txtDict];
        NSString *service = [NSString stringWithFormat:@"_%@._tcp",(NSString *)[_connectionConfig objectForKey:@"bonjourServiceName"]];

        if (subType) {
            service = [service stringByAppendingFormat:@".,_%@",subType];
        }
        int port = (int)[[_connectionConfig objectForKey:@"localBindPort"] integerValue];
        _bonjourService = [[NSNetService alloc] initWithDomain:@"" type:service name:[self name] port:port];
        [_bonjourService setTXTRecordData:bonjourTXTRecord];
//        NSString *test = [[NSString alloc] initWithData:bonjourTXTRecord encoding:NSUTF8StringEncoding];
//        NSLog(@"Set record: %@",test);
        [self publishBonjourService];
    
    } else {
        return;
    }
    
}

- (void) publishBonjourService {

    if (_bonjourService) {
        [_bonjourService publish];
        bonjourPublished = YES;
    }
}

- (void) stopBonjourService {
    
    if (_bonjourService) {
        [_bonjourService stop];
        bonjourPublished = NO;
    }

}

- (BOOL) stopConnectionSynchronous {
    [self stopBonjourService];
    [_connectionProcess stopConnection: YES];
    return YES;
}

- (BOOL) stopConnection {
    [self stopBonjourService];
    [_connectionProcess stopConnection: NO];
    return YES;
}


@end

@implementation NESConnections

- (id)init {
    
    self = [super init];
    
    if (self) {
        rootContainers = [[NSMutableArray alloc] init];
        _statusUpdates = [[NSMutableArray alloc] init];
        containerNames = @{
                           @(NESConnectionLocalForward) : LOCAL_FORWARD_CONTAINER_NAME,
                           @(NESConnectionRemoteForward) : REMOTE_FORWARD_CONTAINER_NAME,
                           @(NESConnectionProxy) : PROXY_CONTAINER_NAME,
                           @(NESConnectionSSH) : SSH_CONTAINER_NAME,
                           @(NESConnectionX11) : X11_CONTAINER_NAME,
                           @(NESConnectionManagedLocalForward) : MANAGED_LOCAL_FORWARD_CONTAINER_NAME,
                           @(NESConnectionManagedRemoteForward) : MANAGED_REMOTE_FORWARD_CONTAINER_NAME,
                           @(NESConnectionManagedProxy) : MANAGED_PROXY_CONTAINER_NAME
                           };
        _statusHasUpdate = _statusUpdated = NO;
        statusLock = [[NSRecursiveLock alloc] init];
    }

    return self;
    
}

- (NSIndexSet *) removeConnection:(NESConnection *)connection {
    NSIndexSet *index = nil;
    NESConnection *container = [connection parent];
    
    // Stop connection if running
    if (([connection status] == NESConnectionConnected)||([connection status] == NESConnectionConnecting)) {
        [connection stopConnection];
    }
    
    
    if (container == self) {
         index = [[NSIndexSet alloc] initWithIndex:[rootContainers indexOfObject:connection]];
        [rootContainers removeObject:connection];
    } else {
        [self deregisterForStatusUpdates:connection];
        index = [container removeConnection:connection];
    }

    [self setConfigUpdated:YES];
    
    return index;
    
}

- (NSIndexSet *) addConnection: (NESConnection *) connection {
    NSIndexSet *index = nil;
    
    if (!connection)
        return nil;

    NESConnection *container = [self getContainerForConnectionType:[connection type]];
    
    if (!container) {
        NSLog(@"ERROR: No container found, this should not happen...");
        return nil;
    }
    
    index = [[NSIndexSet alloc] initWithIndex:[container addConnection:connection]];
    [self registerForStatusUpdates:connection];
    
    [self setConfigUpdated:YES];
    return index;
}

- (NSArray *) updateConnection:(NESConnection *)connection forName:(NSString *)name {
    NESConnection *container = [self getContainerForConnectionType:[connection type]];
    NESConnection *oldConnection = [container findConnectionWithName:name];
    
    [self deregisterForStatusUpdates:oldConnection];
    NSArray *update = [[self getContainerForConnectionType:[connection type]] updateConnection:name withNewConnection:connection];
    [self registerForStatusUpdates:connection];
    [self setConfigUpdated:YES];
    
    return update;
    
}

- (NSMutableArray *) children {
    return rootContainers;
}

- (NSIndexSet *) indexForConnectionTypeContainer:(NSInteger)type {

    // TODO: We shouldn't have done this by container name...
    NSString *containerName = [containerNames objectForKey:@(type)];
    // Search the root array for the connection
    for (NESConnection *connection in rootContainers) {
        if ([connection.name isEqualToString:containerName])
            return [[NSIndexSet alloc] initWithIndex:[rootContainers indexOfObject:connection]];
    }
    
    return nil;
}

- (NSIndexSet *) addContainerForConnectionType:(NSInteger)type {
    NESConnection *container;
    
    container = [[NESConnection alloc] initWithName:[containerNames objectForKey:@(type)] asType:NESConnectionContainer];
    [container setParent:self];
    
    NSUInteger index = [NESConnection indexForInserting:container inArray:rootContainers];
    [rootContainers insertObject:container atIndex:index];

    return [[NSIndexSet alloc] initWithIndex:[rootContainers indexOfObject:container]];

}

- (NESConnection *) getContainerForConnectionType: (NSInteger) type {

    NSIndexSet *index = [self indexForConnectionTypeContainer:type];
    
    if (index != nil)
        return [rootContainers objectAtIndex:[index firstIndex]];
    else {
        return nil;
    }
    
    
}

-(void) initSupportDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    NSString *supportPath = [SUPPORT_DIR stringByExpandingTildeInPath];
    
    if (![fileManager fileExistsAtPath:supportPath isDirectory:&isDir]) {
        
        if (![fileManager createDirectoryAtPath:supportPath withIntermediateDirectories:NO attributes:nil error:nil]) {
            NSLog(@"Error creating preferences directory. Exiting.");
            [NSApp  terminate: nil];
        }
        NSLog(@"Preferences directory created.");
        return;
    }
    
    if (!isDir) {
        NSLog(@"Preferences directory is a file. Terminating.");
        [NSApp  terminate: nil];
    }
    
}

-(void) initPrefsFile {
    NSMutableArray *empty;
    
    empty = [[NSMutableArray alloc] init];
    if ([empty writeToFile:[[PREFS_FULL_PATH stringByExpandingTildeInPath] stringByExpandingTildeInPath] atomically:YES]) {
        NSLog(@"Preferences file created.");
        return;
    }
    
    NSLog(@"Cannot create preferences folder/file.");
    [NSApp  terminate: nil];

}

-(NSDictionary *) connectionsToDictionary {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    for (NESConnection *connection in rootContainers) {
        [dict setValue:[connection asDictionary] forKey:[connection name]];
    }
    
    return dict;
}

- (BOOL) saveConnections {

    if ([[self connectionsToDictionary] writeToFile:[[PREFS_FULL_PATH stringByExpandingTildeInPath] stringByExpandingTildeInPath] atomically:YES]) {
        return YES;
    } else {
        return NO;
    }
}

- (NESConnection *) getHasStatusUpdateConnection {
    [statusLock lock];
    // Return the top item
    NESConnection *connection = [[self statusUpdates] objectAtIndex:0];
    [[self statusUpdates] removeObjectAtIndex:0];
    [statusLock unlock];
    return connection;
}

- (void)fastStopActiveConnections {
    
    for (id container in rootContainers) {
        if ([[container children] count] > 0) {
            for (NESConnection *connection in [container children]) {
                if (([connection status]&NESConnectionConnected)||([connection status]&NESConnectionConnecting)) {
                    [[connection connectionProcess] stopConnection: NO];
                }
            }
        }
    }
    
    
}

- (void)stopActiveConnections {
    NSMutableArray *stoppedConnections = [[NSMutableArray alloc] init];
        
    for (id container in rootContainers) {
        if ([[container children] count] > 0) {
            for (NESConnection *connection in [container children]) {
                if (([connection status]&NESConnectionConnected)||([connection status]&NESConnectionConnecting)) {
                    [stoppedConnections addObject:connection];
                    [[connection connectionProcess] stopConnection: YES];
                }
            }
        }
    }
    
    [self setStoppedConnections:stoppedConnections];
    
}

- (void) restartStoppedConnections{
    
    for (id connection in [self stoppedConnections]){
        [[connection connectionProcess] startConnection];
    }
    
}

- (NSMutableArray *) getStartOnLaunchConnections {

    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (id container in rootContainers) {
        if ([[container children] count] > 0) {
            for (id connection in [container children]) {
                if ([[connection configForKey:@"startOnLaunch"] boolValue] == YES) {
                    [connections addObject:connection];
                }
            }
        }
    }

    return connections;
}

- (void)startOnLaunchConnections {
    
    for (id container in rootContainers) {
        if ([[container children] count] > 0) {
            for (id connection in [container children]) {
                if ([[connection configForKey:@"startOnLaunch"] boolValue] == YES) {
                    [[connection connectionProcess] startConnection];
                }
            }
        }
    }
    
}

- (BOOL) loadConnections {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:[PREFS_FULL_PATH stringByExpandingTildeInPath] isDirectory:NULL])
        [self initPrefsFile];

    [self initSupportDir];
    
    NSMutableDictionary *dict;
    
    dict = [NSMutableDictionary dictionaryWithContentsOfFile:[PREFS_FULL_PATH stringByExpandingTildeInPath]];
    NSArray *keys = [[dict allKeys] sortedArrayUsingComparator:^(NSString *obj1, NSString *obj2) {
        // TODO: Sort non-managed first...
        if (([obj1 hasPrefix:@"Managed"])&&(![obj2 hasPrefix:@"Managed"])) {
            return NSOrderedDescending;
        } else if ((![obj1 hasPrefix:@"Managed"])&&([obj2 hasPrefix:@"Managed"])) {
            return NSOrderedAscending;
        } else
        return [(NSString *)obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    for (id container in keys) {
        NESConnection *connectionContainer = [self fromDictionary:[dict objectForKey:container] withName:container];
        [rootContainers addObject:connectionContainer];
        [connectionContainer setParent:self];
        for (id connection in [connectionContainer children]) {
            [self registerForStatusUpdates:connection];
        }
    }
    
    return YES;
}

- (BOOL) checkDuplicateName: (NSString *) name forConnectionType:(NSInteger) type {
    NESConnection *container = [self getContainerForConnectionType:type];
    
    if ( container == nil)
        return NO;
    else {
        if ([container findConnectionWithName:name] != nil)
            return YES;
    }
    
    return NO;
}

- (NESConnection *) getConnectionByName: (NSString *) name forConnectionType:(NSInteger) type {
    NESConnection *container = [self getContainerForConnectionType:type];
    
    if ( container == nil)
        return nil;
    else {
        return [container findConnectionWithName:name];
    }

}


- (BOOL) hasUnManagedConnections {
    
    for (NESConnection *connection in rootContainers) {
        
        if (![[connection name] hasPrefix:@"Managed"]) {
            return YES;
        }
        
    }
    
    return NO;
}

- (BOOL) hasManagedConnections {
    
    for (NESConnection *connection in rootContainers) {
        if ([[connection name] hasPrefix:@"Managed"]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) hasActiveConnections {
    
    for (NESConnection *container in rootContainers) {
        if ([[container children] count] > 0) {
            for (NESConnection *connection in [container children]) {
                if ([connection isActive]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (NESConnection *) findConnectionWithUUID:(NSString *)UUID {
    
    for (NESConnection *container in rootContainers) {
        NESConnection *connection = [container findConnectionWithUUID:UUID];
        if (connection) {
            return connection;
        }
    }
    
    return nil;
}


- (NSMutableArray *) findConnectionsWithStatus:(NESConnectionStatus)status {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (NESConnection *container in rootContainers) {
        [result addObjectsFromArray:[container findConnectionsWithStatus:status]];
    }
    
    return result;
}

- (NSMutableArray *) getManagedConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (id container in rootContainers) {
        if ([[container children] count] > 0) {
            for (id connection in [container children]) {
                if ([[connection configForKey:@"managedConnection"] boolValue] == YES) {
                    [connections addObject:connection];
                }
            }
        }
    }
    
    return connections;
}


- (void) checkManagedConnectionsForUpdates: (void (^)(NSMutableDictionary *config))completionHandler {

    for (id container in rootContainers) {
        if (([[container children] count] > 0) && ([[container name] hasPrefix:@"Managed"])) {
            for (NESManagedConnection *connection in [container children]) {
                NESConnectionStatus oldStatus = [connection status];
                [connection queueStatusUpdate:NESConnectionUpdatingConfig withData:@"Updating connection"];
                [connection updateConfiguration:^(NSMutableDictionary *config) {
                    if (config) {
                        completionHandler(config);
                    } else {
                        // Restore old status unless something happened in the mean time...
//                        if ([connection status]&NESConnectionUpdatingConfig) {
//                            [connection queueStatusUpdate:oldStatus withData:@"Restoring old status"];
//                        }
                        if ([[self findConnectionsWithStatus:NESConnectionUpdatingConfig] count] == 0) {
                            // This tells the caller we're done.
                            completionHandler(nil);
                        }
                        
                    }
                }];
            }
        }
    }
    
    
}

- (void) registerForStatusUpdates:(NESConnection *) connection {
    
    [connection addObserver:self forKeyPath:@"connectionStatus.statusMessages" options:NSKeyValueObservingOptionNew context:(__bridge void *)(connection)];
    
}

- (void) deregisterForStatusUpdates:(NESConnection *) connection {
    
    [connection removeObserver:self forKeyPath:@"connectionStatus.statusMessages"];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"connectionStatus.statusMessages"]) {
        [statusLock lock];
        [[self statusUpdates] addObject:(__bridge NESConnection *)context];
        [self setStatusHasUpdate:YES];
        [statusLock unlock];
    } 
}

@end
