//
//  NESKeychain.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/1/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Security/Security.h>

#define SERVICE_NAME(name,type) ((type!=0)?(char *)[[NSString stringWithFormat:@"net.edgeservices (%ld) - %@",(long)type,name] UTF8String]:(char *)[[NSString stringWithFormat:@"net.edgeservices (%@)",name] UTF8String])
#define APP_NAME @"Secure Pipes"

@interface NESKeychain : NSObject

+ (BOOL) keyChainItemExists:(NSString *)name withType:(NSInteger)type;
+ (BOOL) addKeyChainItem:(NSString *)name withUser:(NSString *)user andPassword:(NSString *)passwd andType:(NSInteger)type;
+ (BOOL) updateKeyChainItem:(NSString *)name withName:(NSString *)newName andUser:(NSString *)user andPassword:(NSString *)passwd andType:(NSInteger)type;
+ (BOOL) removeKeyChainItem:(NSString *)name andType:(NSInteger)type;
+ (NSString *)getPassword:(NSString *)name andType:(NSInteger)type;

@end


