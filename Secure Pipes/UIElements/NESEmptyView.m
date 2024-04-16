//
//  NESEmptyView.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 8/3/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESEmptyView.h"

@implementation NESEmptyView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _fillColor = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    if (!_fillColor) {
        [[NSColor whiteColor] set];
    } else {
        [_fillColor set];
    }
    NSRectFill(dirtyRect);
}

-(BOOL) isOpaque {
    return NO;
}

@end
