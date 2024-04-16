/**
 @file CCFBrowserTextFieldButtonImage.m
 @author Alan Duncan (www.cocoafactory.com)
 
 @date 2012-09-20 10:12:10
 @version 1.0
 
 Copyright (c) 2012 Cocoa Factory, LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "NESPopoverTextFieldButton.h"
#import "NESPopoverTextField.h"

@implementation NESPopoverTextFieldButton {

}

+ (NSSize)browserImageSize {
    return NSMakeSize(14,14);
}

- (void)setButtonPopoverMessage:(NSString *)msg withType:(NESPopoverTextType)type {
    
    if ((_popover != nil) && ([_popover isShown])) {
            return;
    }
    
    pmsg = (msg==nil)?@"":msg;
    ptype = type;
    // Install the appropriate image
    NSImage *image;
    switch (type) {
        case NESActionPopover:
            image = [NSImage imageNamed:NSImageNameActionTemplate];
            break;
        case NESErrorPopover:
            image = [NSImage imageNamed:NSImageNameInvalidDataFreestandingTemplate];
            break;
        case NESWarningPopover:
            image = [NSImage imageNamed:NSImageNameCaution];
            break;
        default:
            image = [NSImage imageNamed:NSImageNameInfo];
            break;
    }
    
    [image setSize:NSMakeSize(14,14)];
    [self setImage: image];
    [self setImagePosition:NSImageOnly];
    [self setAction:@selector(showPopover)];
    [self setHidden:NO];
    
}

- (void)showPopover {
    
    if (_popover != nil) {
        if ([_popover isShown]) {
            return;
        }
    }

    NSViewController *controller = [[NSViewController alloc] init];
    
    // Install our Popover with message
    _text = [[NSTextField alloc] init];
    [_text setStringValue:pmsg];
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
    [_dismiss setTitle:POPUP_DISMISS_LABEL];
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

    [self setAction:@selector(dismissPopover)];
    [_popover showRelativeToRect:[self bounds] ofView:self preferredEdge:NSMaxXEdge];
}

- (void)dismissPopover {
    [self setAction:@selector(showPopover)];
    [_popover close];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if( !self ) return nil;
    
    [self setButtonType:NSButtonTypeMomentaryPushIn];
    [self setBordered:NO];
    [self setHidden:YES];
    [self setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin];
    
    return self;
}

- (NESPopoverTextType)type {
    return ptype;
}
- (void)setFrame:(NSRect)browserRect {
    [super setFrame:browserRect];
    self.target = self;
}

- (BOOL)canBecomeKeyView {
    return NO;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [NSApp preventWindowOrdering];
    [super mouseDown:theEvent];
}

@end
