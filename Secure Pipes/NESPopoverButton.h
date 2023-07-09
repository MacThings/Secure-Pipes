//
//  NESPopupButton.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/16/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// We should make all these things configurable eventually
#define POPUP_WIDTH 270
#define POPUP_PADDING 10
#define POPUP_FONT_SIZE 11
#define POPUP_BUTTON_AREA_HEIGHT 40
#define POPUP_CLEAR_LABEL @"Clear"

@interface NESPopoverButton : NSButton {
    void (^_completionHandler)(void);
}

@property (copy) NSPopover *popover;
@property (copy) NSButton *dismiss;
@property (copy) NSTextField *text;
@property (copy) NSView *content;
@property (strong) id associatedObject;
@property (strong) NSString *popoverMessage;
@property (strong) NSString *popoverDismissText;

- (void) showPopover;
- (void) setCompletionHandler:(void(^)(void))handler;

@end
