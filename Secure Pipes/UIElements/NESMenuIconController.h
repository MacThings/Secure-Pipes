//
//  NESMenuIconController.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/10/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NESConnection.h"

@interface NESMenuIconController : NSObject {
    NSTimer *animTimer;
    NSInteger currentFrame, direction;
    NSLock *lock;
}

@property (strong) NSStatusItem *statusBarItem;
@property (atomic) BOOL darkMode;

- (void)startAnimation;
- (void)stopAnimation;
- (void)setMenuForConnections:(NESConnections *) connections;

@end
