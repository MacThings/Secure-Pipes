//
//  NESConfirmationSheet.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 2/10/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESConfirmationSheet.h"

@implementation NESConfirmationSheet 

- (void)awakeFromNib {
    
}

- (void) moveStuff {
 
    float textHeight = [((NSTextFieldCell *)[_confirmationTextField cell]) cellSizeForBounds:NSMakeRect(0, 0,335, FLT_MAX)].height;
    if (textHeight>76) {
        float diff = textHeight-76;
        // Resize the window
        NSRect frame;
        frame = [[self window] frame];
        frame.size.height += diff;
        [[self window] setFrame:frame display:YES animate:YES];
        frame = [_confirmButton frame];
        frame.origin.y -= diff;
        [_confirmButton setFrame:frame];
        frame = [_cancelButton frame];
        frame.origin.y -= diff;
        [_cancelButton setFrame:frame];
        frame = [_confirmationTextField frame];
        frame.origin.y -= diff;
        frame.size.height += diff;
        [_confirmationTextField setFrame:frame];
        [[self window] viewsNeedDisplay];
    }
    
    
}

- (id) init {
    
    self = [super initWithWindowNibName:@"ConfirmationSheet"];
    
    if (self) {
        // Put initializers here.
        [self loadWindow];
    }
    
    return self;
}

- (void) setConfirmationText:(NSString *)confirmationText {
    
    [_confirmationTextField setStringValue:confirmationText];

}

- (void) setConfirmButtonText:(NSString *)confirmButtonText {
    [_confirmButton setStringValue:confirmButtonText];
}

- (void) setCancelButtonText:(NSString *)cancelButtonText {
    [_cancelButton setStringValue:cancelButtonText];
}

- (void) setCancelButtonHidden:(BOOL) hidden {
    [_cancelButton setHidden:hidden];
}

- (void) setWindowImage:(NSImage *)windowImage {
    [_image setImage:windowImage];
}

- (IBAction)cancelClicked:(id)sender {

    [_parent endSheet:[self window] returnCode:NSModalResponseCancel];
    
}

- (IBAction)okayClicked:(id)sender {

    [_parent endSheet:[self window] returnCode:NSModalResponseOK];
    
}


@end
