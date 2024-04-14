//
//  NESConnectionCellView.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 1/19/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConnectionCellView.h"

@implementation NESConnectionCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
    
    return;
    NSArray *subViews = [self subviews];
    NSLog(@"Count: %lu",(unsigned long)[subViews count]);
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    //CGContextSaveGState(context);
    
    CGFloat radius = CGRectGetMaxY(rect)*0.20;
    CGFloat puffer = CGRectGetMaxY(rect)*0.10;
    CGFloat maxX = CGRectGetMaxX(rect) - puffer;
    CGFloat maxY = CGRectGetMaxY(rect) - puffer;
    CGFloat minX = CGRectGetMinX(rect) + puffer;
    CGFloat minY = CGRectGetMinY(rect) + puffer;
    
    
    CGContextBeginPath(context);
    CGContextSetLineWidth(context, 0.1);
    CGContextSetFillColorWithColor(context, [[NSColor colorWithSRGBRed:0.0 green:0.0 blue:1.0 alpha:0.2] CGColor]);
    CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
    CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
    CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
    CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
//    if (self.badgeStyle.badgeShadow) {
//        CGContextSetShadowWithColor(context, CGSizeMake(1.0,1.0), 3, [[UIColor blackColor] CGColor]);
//    }
    CGContextClosePath(context);
    //CGContextFillPath(context);
    CGContextStrokePath(context);
    
    //CGContextRestoreGState(context);
    
    
    // Drawing code here.
}

@end
