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
+ (id)currentUser
{
    if (!_currentUser) {
        _currentUser = [[self alloc] initWithName: NSUserName()];
    }
    return _currentUser;
}

/*
 
 init with user name
 
 */
- (id)initWithName:(NSString *)name
{
    if ([super init]) {
        CBIdentityAuthority *authority = [CBIdentityAuthority
                                          defaultIdentityAuthority];    // default is local and network
        _user =[CBIdentity identityWithName:name authority:authority]; //searches for full and logon names
            }
    return self;
}
/*
 
 user is member of admin group
 
 */
- (BOOL)isMemberOfAdminGroup
{
    CBIdentityAuthority *authority =[CBIdentityAuthority
                                     defaultIdentityAuthority]; // default is local and network
    // admin is 80, user is 20.
    // to see user group membership type 'id' at terminal
    // for list of groups type 'more /etc/group'
    return [_user isMemberOfGroup:[CBGroupIdentity
                                   groupIdentityWithPosixGID:80 authority:authority]];
}

@end
