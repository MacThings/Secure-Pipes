//
//  NESGetScriptOutput.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 11/14/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESConnection.h"

@interface NESGetScriptOutput : NSObject {
    NSString *scriptName;
    NSMutableArray *arguments;
    NSTask *task;
    NSString *output;
}

@property (weak) NESConnection *connection;

- (id) initWithScript: (NSString *)script;
- (BOOL) scriptExists;
- (BOOL) scriptIsExecutable;
- (void) runWithCompletionHandler: (void (^)(NSString *output))completionHandler;


@end
