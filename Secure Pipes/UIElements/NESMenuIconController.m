//
//  NESMenuIconController.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/10/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESMenuIconController.h"

@implementation NESMenuIconController

- (id) init {
    
    self = [super init];
    
    if (self) {
        direction = 0;
        lock = [[NSLock alloc] init];
    }
    
    return self;
    
}

- (void)startAnimation {
    currentFrame = 0;
    direction = 1;
    animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/5.0 target:self selector:@selector(updateImage:) userInfo:nil repeats:YES];
}

- (void)stopAnimation
{
    direction = 0;
    [animTimer invalidate];
}

- (void)updateImage:(NSTimer*)timer
{
    
    currentFrame += direction;
    NSImage* image = [NSImage imageNamed:[NSString stringWithFormat:@"menu_connecting%d",(int)currentFrame]];
    NSImage* altImage = [NSImage imageNamed:[NSString stringWithFormat:@"menu_connecting%d_inverse",(int)currentFrame]];
    [_statusBarItem.button setImage:image];
    [_statusBarItem.button setAlternateImage:altImage];
    
    if (currentFrame == 5)
        direction = -1;
    else if (currentFrame == 1)
        direction = 1;
    
}

- (void) setMenuForConnections:(NESConnections *)connections {
    
    [lock lock];
    
    if ([[connections findConnectionsWithStatus:NESConnectionConnecting] count]>0) {
        if (direction==0)
            [self startAnimation];
        [lock unlock];
        return;
    } else
        [self stopAnimation];
    
    // Check to see how many connections active
    NSUInteger activeCount = [[connections findConnectionsWithStatus:NESConnectionConnected] count];
    NSString *imageName = @"menu_disconnected";
    if (activeCount>0) {
        if (activeCount>1)
            imageName = @"menu_connected_multiple";
        else
            imageName = @"menu_connected";
    }
    
    NSImage* image = [NSImage imageNamed:imageName];
    NSImage* altImage = [NSImage imageNamed:[NSString stringWithFormat:@"%@_inverse",imageName]];
    [_statusBarItem.button setImage:image];
    [_statusBarItem.button setAlternateImage:altImage];

    
    [lock unlock];
    
}

@end
