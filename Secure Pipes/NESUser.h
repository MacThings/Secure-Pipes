//
//  NESUser.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/11/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//
//  Created by Jonathan on 31/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Collaboration/Collaboration.h>

@interface NESUser : NSObject {
    //CBIdentity *_user;
}

@property (strong) CBIdentity *user;

+ (id)currentUser;
- (id)initWithName:(NSString *)name;
- (BOOL)isMemberOfAdminGroup;

@end
