//
//  NESSelectHostnameScriptDelegate.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 11/13/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESSelectHostnameScriptDelegate.h"

@implementation NESSelectHostnameScriptDelegate

- (id) init {
    
    self = [super init];
    
    if (self) {
        
        // Do any init here...
        
        
    }
    
    return self;
    
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
    return YES;
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError *__autoreleasing *)outError {
    
    return YES;
    
}

- (void)panel:(id)sender didChangeToDirectoryURL:(NSURL *)url {
    NSLog(@"didChangeDirectory...");
}

- (NSString *)panel:(id)sender userEnteredFilename:(NSString *)filename confirmed:(BOOL)okFlag {
    
    return filename;
}

- (void)panel:(id)sender willExpand:(BOOL)expanding {
    NSLog(@"Expanding: %d",expanding);
}

- (void)panelSelectionDidChange:(id)sender {
    NSLog(@"Selection changed...");
}

@end
