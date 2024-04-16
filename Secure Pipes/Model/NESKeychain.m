
//
//  NESKeychain.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/1/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESKeychain.h"
#import "NESConnection.h"

@implementation NESKeychain

+ (OSStatus) getKeychainItem: (SecKeychainItemRef *) itemRef withUser: (NSString *)user andName:(NSString *)name andType:(NSInteger)type {
    OSStatus status;
    char *service = SERVICE_NAME(name,type);
    UInt32 serviceLength = (UInt32)strlen(service);
    const char *nameString = (user)?[user UTF8String]:NULL;
    int nameLength = (user)?(int)strlen([user UTF8String]):0;
    
    
    status = SecKeychainFindGenericPassword (
                                             NULL,                      // default keychain
                                             serviceLength,             // length of service name
                                             service,                   // service name
                                             nameLength,                // length of account name
                                             nameString,                // account name
                                             NULL,                      // length of password
                                             NULL,                      // pointer to password data
                                             itemRef                    // the item reference
                                             );
    
    //NSLog(@"Find Status for %@: %d",name,status);
    return status;
}

+ (BOOL) keyChainItemExists:(NSString *)name withType:(NSInteger)type {
    OSStatus status;
    char *service = SERVICE_NAME(name,type);
    UInt32 serviceLength = (UInt32)strlen(service);
    
    status = SecKeychainFindGenericPassword (
                                             NULL,                      // default keychain
                                             serviceLength,             // length of service name
                                             service,                   // service name
                                             0,                      // length of account name
                                             NULL,                      // account name
                                             NULL,                      // length of password
                                             NULL,                      // pointer to password data
                                             NULL                    // the item reference
                                             );
    //NSLog(@"Find Status: %d",status);
    return (status==errSecSuccess);
    
}

+ (BOOL) addKeyChainItem:(NSString *)name withUser:(NSString *)user andPassword:(NSString *)passwd andType:(NSInteger)type {
    
    OSStatus status;
    char *service = SERVICE_NAME(name,type);
    UInt32 serviceLength = (UInt32)strlen(service);
    
    status = SecKeychainAddGenericPassword (
                                                NULL,                       // default keychain
                                                serviceLength,              // length of service name
                                                SERVICE_NAME(name,type),    // service name
                                                (int)strlen([user UTF8String]),         // length of account name
                                                [user UTF8String],          // account name
                                                (int)strlen([passwd UTF8String]),       // length of password
                                                [passwd UTF8String],        // pointer to password data
                                                NULL                        // the item reference
                                                );
        
    //NSLog (@"Password save status: %@",[self errorMessageForCode:status]);
    
    return (status==errSecSuccess);
}

+ (BOOL) updateKeyChainItem:(NSString *)name withName:(NSString *)newName andUser:(NSString *)user andPassword:(NSString *)passwd andType:(NSInteger)type {
    
    // TODO: Maybe we can do a real update in the future, but for now let's just delete and add again
    [self removeKeyChainItem:name andType:type];
    return [self addKeyChainItem:newName withUser:user andPassword:passwd andType:type];
    
}

+ (BOOL) removeKeyChainItem:(NSString *)name andType:(NSInteger)type {

    OSStatus status;
    SecKeychainItemRef itemRef;

    if ([self keyChainItemExists:name withType:type]) {
        
        [self getKeychainItem:&itemRef withUser:nil andName:name andType:type];
        status = SecKeychainItemDelete(itemRef);
        CFRelease(itemRef);
        return status;
    } else {
        // NSLog(@"WARNING: Cannot find connection %@ in key chain.",name);
        return NO;
    }
    
}

+ (NSString *)getPassword:(NSString *)name andType:(NSInteger)type {

    OSStatus status;
    char *service = SERVICE_NAME(name,type);
    UInt32 serviceLength = (UInt32)strlen(service);
    UInt32 passwordLength = 0;
    void  *passwordData = nil;
    SecKeychainItemRef itemRef;

    status = SecKeychainFindGenericPassword (
                                              NULL,                 // default keychain
                                              serviceLength,        // length of service name
                                              service,              // service name
                                              0,                    // length of account name
                                              NULL,                 // account name
                                              &passwordLength,      // length of password
                                              &passwordData,        // pointer to password data
                                              &itemRef              // the item reference
                                              );
    
    if (status == errSecSuccess) {
        NSString *pass = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
        if (itemRef)
            CFRelease(itemRef);
        return (passwordLength>0)?pass:nil;
    } else
        return nil;
    
}

+ (NSString *) errorMessageForCode:(OSStatus)code {
    
    return (__bridge NSString *)(SecCopyErrorMessageString (code,NULL));
    
}

@end
