//
//  NESUser.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/11/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//
//  Created by Jonathan on 31/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NESUser.h"

static NESUser *_currentUser = nil;

@implementation NESUser

/*
 
 current user
 
 */
+ (instancetype)currentUser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentUser = [[self alloc] initWithName:NSUserName()];
    });
    return _currentUser;
}

/*
 
 init with user name
 
 */
- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        // Avoid synchronous, heavy operations in `dispatch_once`
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            CBIdentityAuthority *authority = [self defaultAuthority];
            self->_user = [CBIdentity identityWithName:name authority:authority];
            if (!self->_user) {
                NSLog(@"Failed to initialize CBIdentity with name: %@", name);
                // Additional error handling or fallback logic can go here
            }
        });
    }
    return self;
}

/*
 
 user is member of admin group
 
 */
- (BOOL)isMemberOfAdminGroup {
    if (!_user) {
        NSLog(@"User identity not initialized.");
        return NO;
    }
    CBGroupIdentity *adminGroup = [CBGroupIdentity groupIdentityWithPosixGID:80 authority:[self defaultAuthority]];
    return [_user isMemberOfGroup:adminGroup];
}

// Helper method to get the default authority
- (CBIdentityAuthority *)defaultAuthority {
    static CBIdentityAuthority *authority = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        authority = [CBIdentityAuthority defaultIdentityAuthority];
    });
    return authority;
}

@end
