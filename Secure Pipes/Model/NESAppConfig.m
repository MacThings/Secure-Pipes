//
//  NESAppConfig.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/13/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESAppConfig.h"

@implementation NESAppConfig


- (id)init
{
    self = [super init];
    if (self) {
        if (!_configDictionary)
            [self loadConfig];
    }
    return self;
}

+(NSDictionary *) defaultConfig {

    NSDictionary *defaults = @{@"useNotificationCenter" : @YES,
                               @"allowSavePassword" : @YES, @"relaunchOnWake" : @NO,
                               @"showPasswordDialog" : @YES, @"managedConnectionUpdateInterval" : @300.0,
                               @"defaultManagedConnectionServer" : @"https://www.opoet.com/ticket",
                               @"enableManagedConnections" : @NO, @"managedConnectionKeyChainName" : @"Secure Pipes Management Server"
                               };

    return defaults;
}

-(void) initConfig {
    NSDictionary *defaults = [NESAppConfig defaultConfig];
    
    if ([defaults writeToFile:[[CONFIG_FULL_PATH stringByExpandingTildeInPath] stringByExpandingTildeInPath] atomically:YES]) {
        return;
    }
    
    NSLog(@"Secure Pipes: ERROR:Cannot create preferences folder/file.");
    [NSApp  terminate: nil];
    return;
}


- (BOOL) loadConfig {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:[CONFIG_FULL_PATH stringByExpandingTildeInPath] isDirectory:NULL])
        [self initConfig];
    
    _configDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:[CONFIG_FULL_PATH stringByExpandingTildeInPath]];
    
    return YES;
}

//- (NSMutableDictionary *) configDictionary {
//    return _configDictionary;
//}

- (NSString *) configForKey:(id)key {
    
    NSString *val = [_configDictionary objectForKey:key];
    
    if (!val) {
        val = [[NESAppConfig defaultConfig] objectForKey:key];
    }
    
    return val;
}

- (void) setConfigForKey:(NSString *)key withValue:(id)value {
    
    [_configDictionary setObject:value forKey:key];
    
}

- (BOOL) saveConfig {
    
    if ([_configDictionary writeToFile:[[CONFIG_FULL_PATH stringByExpandingTildeInPath] stringByExpandingTildeInPath] atomically:YES]) {
        return YES;
    } else {
        return NO;
    }
}



@end
