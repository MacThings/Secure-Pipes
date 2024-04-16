//
//  Log.h
//  Secure Pipes
//
//  Created by Timothy Stonis on 6/25/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSLog(args...) _Log(@"DEBUG ", __FILE__,__LINE__,__PRETTY_FUNCTION__,args);

@interface Log : NSObject

void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format,...);

@end
