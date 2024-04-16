//
//  NESAppConfig.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/13/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NESConnection.h"

#define CONFIG_FILE @"net.edgeservices.sp-config.plist"
#define CONFIG_FULL_PATH PREFS_DIR @"/" CONFIG_FILE

@interface NESAppConfig : NSObject

@property (strong) NSMutableDictionary *configDictionary;

- (BOOL) loadConfig;
- (BOOL) saveConfig;
- (NSString *) configForKey:(id)key;
- (void) setConfigForKey:(NSString *)key withValue:(id)value;
+ (NSDictionary *) defaultConfig;

@end
