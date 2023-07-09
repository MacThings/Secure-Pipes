/**
 @file CCFBrowserTextField.m
 @author Alan Duncan (www.cocoafactory.com)
 
 @date 2012-09-20 10:11:23
 @version 1.0
 
 Copyright (c) 2012 Cocoa Factory, LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "NESPopoverTextField.h"
#import "NESPopoverTextFieldCell.h"
#import "NESPopoverTextFieldButton.h"
#import "NESPopoverTextField+FirstResponderNotification.h"
#import <objc/runtime.h>

@implementation NESPopoverTextField {
    NESPopoverTextFieldButton *_popoverButton;
}

+ (Class)cellClass {
    return [NESPopoverTextFieldCell class];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    return [self _initTextFieldCompletion];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    return [self _initTextFieldCompletion];
}

//- (BOOL)becomeFirstResponder {
//    
//    BOOL didBecomeFirstResponder = [super becomeFirstResponder];
//    NSNotification *notification = [NSNotification
//                                    notificationWithName:@"firstResponderChangedNotification"
//                                    object:self];
//    
//    if ( [self delegate] && [[self delegate]
//                             respondsToSelector:@selector(firstResponderChanged:)] ) {
//        [(id <FirstResponderNotification>)[self delegate] firstResponderChanged:notification];
//    }
//    [[NSNotificationCenter defaultCenter] postNotification:notification];
//
//    return didBecomeFirstResponder;
//    
//}

#pragma mark - Public API

- (void) setButtonEnabled:(BOOL)flag {
    [_popoverButton setEnabled:flag];
}

- (void) setButtonHidden:(BOOL)flag {
    [_popoverButton setHidden:flag];
}

- (BOOL) isButtonHidden {
    return [_popoverButton isHidden];
}

- (NESPopoverTextType)popoverType {
    return [_popoverButton type];
}

- (void) setButtonPopoverMessage:(NSString *) msg withType:(NESPopoverTextType) type {
    // Just pass this through to the button...
    [_popoverButton setButtonPopoverMessage:msg withType:type];
}

#pragma mark - NSControl subclass methods

- (void)setEditable:(BOOL)flag {
    [super setEditable:flag];
    [_popoverButton setEnabled:flag];
}

- (void)resetCursorRects {
    [self addCursorRect:self.bounds cursor:[NSCursor IBeamCursor]];
    if( ![_popoverButton isHidden] ) {
        [self addCursorRect:[_popoverButton frame] cursor:[NSCursor arrowCursor]];
    }
}

- (void)didAddSubview:(NSView *)subview {
    if( subview == _popoverButton )
        return;
    [_popoverButton removeFromSuperview];
    [self addSubview:_popoverButton];
}

- (id)_initTextFieldCompletion {
    if( !_popoverButton ) {

        NSSize browserImageSize = [NESPopoverTextFieldButton browserImageSize];
        NSRect buttonFrame = NSMakeRect(0.0f, 0.0f, browserImageSize.width, browserImageSize.height);
        _popoverButton = [[NESPopoverTextFieldButton alloc] initWithFrame:buttonFrame];
        buttonFrame = [NESPopoverTextFieldCell rectForBrowserFrame:self.bounds];
        
        [self _setCellClass];
        
        [self addSubview:_popoverButton];
        self.autoresizesSubviews = YES;
        [_popoverButton setFrame:buttonFrame];
    }
    return self;
}

- (void)_setCellClass {
    Class customClass = [NESPopoverTextFieldCell class];
    
    //  since we are switching the isa pointer, we need to guarantee that the class layout in memory is the same
    NSAssert(class_getInstanceSize(customClass) == class_getInstanceSize(class_getSuperclass(customClass)), @"Incompatible class assignment");
    
    //  switch classes if we are not already switched
    NSCell *cell = [self cell];
    if( ![cell isKindOfClass:[NESPopoverTextFieldCell class]] ) {
        object_setClass(cell, customClass);
    }
}

@end
