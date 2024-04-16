//
//  NESPopupButton.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/16/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESPopoverButton.h"
#import "NESConnection.h"

@implementation NESPopoverButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _completionHandler = nil;
        _popoverDismissText = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void)dismissPopover {
    //[self setAction:@selector(showPopover)];
    if (_completionHandler != nil) {
        _completionHandler();
    }
    _completionHandler = nil;
    [_popover close];
}

- (void) setCompletionHandler:(void(^)(void))handler {
    
    _completionHandler = [handler copy];
    
}


- (void) showPopover {
    
    if (_popover != nil) {
        if ([_popover isShown]) {
            
            [_popover close];
            return;
        }
    }
    
    NSViewController *controller = [[NSViewController alloc] init];
    
    // Install our Popover with message
    _text = [[NSTextField alloc] init];
    [_text setStringValue:_popoverMessage];
    [_text setFont:[NSFont messageFontOfSize:POPUP_FONT_SIZE]];
    [_text setBordered:NO];
    [_text setDrawsBackground:NO];
    [_text setSelectable:NO];
    [_text setTextColor:[NSColor whiteColor]];
    float textHeight = [((NSTextFieldCell *)[_text cell]) cellSizeForBounds:NSMakeRect(0, 0, POPUP_WIDTH-(2*POPUP_PADDING), FLT_MAX)].height;
    [_text setFrame:NSMakeRect(POPUP_PADDING, POPUP_BUTTON_AREA_HEIGHT, POPUP_WIDTH-(2*POPUP_PADDING), textHeight)];
    
    _dismiss = [[NSButton alloc] init];
    [_dismiss setButtonType:NSButtonTypeMomentaryPushIn];
    [_dismiss setBezelStyle:NSBezelStyleBadge];
    [_dismiss setFont:[NSFont messageFontOfSize:POPUP_FONT_SIZE]];
    if (_popoverDismissText == nil) {
        [_dismiss setTitle:POPUP_CLEAR_LABEL];
    } else {
        [_dismiss setTitle:_popoverDismissText];
    }
    [_dismiss sizeToFit];
    [_dismiss setTarget:self];
    [_dismiss setAction:@selector(dismissPopover)];
    [_dismiss setFrame:NSMakeRect(POPUP_WIDTH-_dismiss.bounds.size.width-POPUP_PADDING, POPUP_PADDING, _dismiss.bounds.size.width, _dismiss.bounds.size.height)];
    
    _content = [[NSView alloc] initWithFrame:NSMakeRect(0,0,POPUP_WIDTH,textHeight+POPUP_BUTTON_AREA_HEIGHT+POPUP_PADDING)];
    
    [controller setView:_content];
    [_content addSubview:_text];
    [_content addSubview:_dismiss];
    
    _popover = [[NSPopover alloc] init];
    [_popover setContentViewController:controller];
    [_popover setAnimates:YES];
    //[_popover setAppearance:NSPopoverAppearanceHUD];
    [_popover setBehavior:NSPopoverBehaviorApplicationDefined];
    
    //[self setAction:@selector(dismissPopover)];
    [_popover showRelativeToRect:[self bounds] ofView:self preferredEdge:NSMaxXEdge];
}

@end
