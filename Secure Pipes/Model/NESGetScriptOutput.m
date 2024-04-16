//
//  NESGetScriptOutput.m
//  Secure Pipes
//
//  Created by Timothy Stonis on 11/14/14.
//  Copyright (c) 2014 Timothy Stonis. All rights reserved.
//

#import "NESGetScriptOutput.h"


@interface NSString (Search)
- (NSMutableArray *)searchTerms;
@end

@implementation NSString (Search)

- (NSMutableArray *)searchTerms {
    
    // Strip whitespace and setup scanner
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *searchString = [self stringByTrimmingCharactersInSet:whitespace];
    NSScanner *scanner = [NSScanner scannerWithString:searchString];
    [scanner setCharactersToBeSkipped:nil]; // we'll handle whitespace ourselves
    
    // A few types of quote pairs to check
    NSDictionary *quotePairs = @{@"\"": @"\"",
                                 @"'": @"'",
                                 @"\u2018": @"\u2019",
                                 @"\u201C": @"\u201D"};
    
    // Scan
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSString *substring = nil;
    while (scanner.scanLocation < searchString.length) {
        // Check for quote at beginning of string
        unichar unicharacter = [self characterAtIndex:scanner.scanLocation];
        NSString *startQuote = [NSString stringWithFormat:@"%C", unicharacter];
        NSString *endQuote = [quotePairs objectForKey:startQuote];
        if (endQuote != nil) { // if it's a valid start quote we'll have an end quote
            // Scan quoted phrase into substring (skipping start & end quotes)
            [scanner scanString:startQuote intoString:nil];
            [scanner scanUpToString:endQuote intoString:&substring];
            [scanner scanString:endQuote intoString:nil];
        } else {
            // Single word that is non-quoted
            [scanner scanUpToCharactersFromSet:whitespace intoString:&substring];
        }
        // Process and add the substring to results
        if (substring) {
            substring = [substring stringByTrimmingCharactersInSet:whitespace];
            if (substring.length) [results addObject:substring];
        }
        // Skip to next word
        [scanner scanCharactersFromSet:whitespace intoString:nil];
    }
    
    return results;
    
}

@end


@implementation NESGetScriptOutput

- (id) initWithScript: (NSString *)script {
    
    self = [super init];
    
    if (self) {
        
        NSMutableArray *split = [script searchTerms];
        scriptName = [split objectAtIndex:0];
        [split removeObjectAtIndex:0];
        if ([split count]>=1) {
            arguments = split;
        } else {
            arguments = nil;
        }
        
    }
    
    return self;
}


- (BOOL) scriptExists {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [scriptName stringByExpandingTildeInPath];
    
    NSLog(@"Path: %@",fullPath);

    return [fileManager fileExistsAtPath:fullPath];
}

- (BOOL) scriptIsExecutable {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [scriptName stringByExpandingTildeInPath];
    
    return [fileManager isExecutableFileAtPath:fullPath];
}


- (void) runWithCompletionHandler: (void (^)(NSString *output))completionHandler {
    
    task = [[NSTask alloc] init];
    NSString *fullPath = [scriptName stringByExpandingTildeInPath];
    
    [task setLaunchPath:fullPath];
    NSPipe *readPipe = [[NSPipe alloc] init];
    NSFileHandle *fh = [readPipe fileHandleForReading];
    
    [task setStandardOutput:readPipe];
    //[task setStandardError:readPipe];
    if (arguments != nil) {
        [task setArguments:arguments];
    }
    
    if (_connection) {
        NSMutableDictionary *env = [[NSMutableDictionary alloc] initWithDictionary:[task environment]];
        [env setObject:[_connection name] forKey:@"CONNECTION_NAME"];
        [task setEnvironment:env];
    }
    
    
    [task launch];
    [task waitUntilExit];
    output = [[NSString alloc] initWithData:[fh readDataToEndOfFile] encoding:NSUTF8StringEncoding];

    // Clean-up any whitespace (thank you SO)
    NSArray *split = [output componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    output = [split componentsJoinedByString:@""];
    
    completionHandler(output);
}

@end

