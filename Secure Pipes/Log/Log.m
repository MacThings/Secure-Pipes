//
//  Log.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 6/25/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "Log.h"

@implementation Log

void append(NSString *msg) {
    // get path to Documents/somefile.txt
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    //NSString *path = [documentsDirectory stringByAppendingPathComponent:@"logfile.txt"];
    NSString *path = [@"~/Library/Application Support/Secure Pipes/sp.log" stringByExpandingTildeInPath];
    // create if needed
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
        fprintf(stderr,"Creating file at %s",[path UTF8String]);
        [[NSData data] writeToFile:path atomically:YES];
    }
    // append
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format,...) {
    va_list ap;
    va_start (ap, format);
    format = [format stringByAppendingString:@"\n"];
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@",format] arguments:ap];
    va_end (ap);
    //fprintf(stderr,"%s%50s:%3d - %s",[prefix UTF8String], funcName, lineNumber, [msg UTF8String]);
    append(msg);
}

@end

