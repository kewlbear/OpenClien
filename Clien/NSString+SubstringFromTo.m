//
//  NSString+SubstringFromTo.m
//  Clien
//
// Copyright 2013 Changbeom Ahn
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NSString+SubstringFromTo.h"

@implementation NSString (SubstringFromTo)

- (NSString*)substringFrom:(NSString*)from to:(NSString*)to {
    NSRange fromRange = [self rangeOfString:from];
    if (fromRange.location == NSNotFound) {
        NSLog(@"%s: @\"%@\" not found", __func__, from);
        return nil;
    }
    NSRange toRange = [self rangeOfString:to options:0 range:NSMakeRange(fromRange.location + fromRange.length, self.length - fromRange.location - fromRange.length)];
    if (toRange.location == NSNotFound) {
        NSLog(@"%s: @\"%@\" not found", __func__, to);
        return nil;
    }
    return [self substringWithRange:NSMakeRange(fromRange.location + fromRange.length, toRange.location - fromRange.location - fromRange.length)];
}

- (NSString*)stringByRemovingHTMLComments {
    NSMutableString* string = [NSMutableString string];
    NSScanner* scanner = [NSScanner scannerWithString:self];
    while (!scanner.isAtEnd) {
        NSString* part;
        if ([scanner scanUpToString:@"<!--" intoString:&part]) {
            [string appendString:part];
        }
        [scanner scanUpToString:@"-->" intoString:NULL];
    }
    return string;
}

@end
