/**
 @file CCFBrowserTextFieldButtonImage.h
 @author Alan Duncan (www.cocoafactory.com)
 
 @date 2012-09-20 10:12:03
 @version 1.0
 
 Copyright (c) 2012 Cocoa Factory, LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

typedef NS_ENUM(NSUInteger, NESPopoverTextType) {
    NESWarningPopover,
    NESErrorPopover,
    NESActionPopover
};

// We should make all these things configurable eventually
#define POPUP_WIDTH 270
#define POPUP_PADDING 10
#define POPUP_FONT_SIZE 11
#define POPUP_BUTTON_AREA_HEIGHT 40
#define POPUP_DISMISS_LABEL @"Dismiss"

@interface NESPopoverTextFieldButton : NSButton {
    NSString *pmsg;
    NESPopoverTextType ptype;
}

@property (copy) NSPopover *popover;
@property (copy) NSButton *dismiss;
@property (copy) NSTextField *text;
@property (copy) NSView *content;

+ (NSSize)browserImageSize;
- (void)setButtonPopoverMessage:(NSString *)msg withType:(NESPopoverTextType)type;
- (NESPopoverTextType)type;

@end
