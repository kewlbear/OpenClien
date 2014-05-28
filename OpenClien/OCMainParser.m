//
//  OCMainParser.m
//  OpenClien
//
// Copyright 2014 Changbeom Ahn
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

#import "OCMainParser.h"
#import "NSString+SubstringFromTo.h"
#import "NSScanner+Skip.h"
#import "OCBoard.h"

@implementation OCMainParser

- (id)init
{
    self = [super init];
    if (self) {
        // fixme
    }
    return self;
}

+ (NSURL*)URL
{
    return [NSURL URLWithString:@"http://www.clien.net/"];
}

- (NSArray*)parse:(NSData *)data
{
    NSString* response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%s: %@", __func__, response);
    NSMutableArray* array = [NSMutableArray array];
    [array addObject:[self parseSection:[response substringFrom:@"<div id=\"snb_navi1\">" to:@"</div>"] index:1]];
    [array addObject:[self parseSection:[response substringFrom:@"<div id=\"snb_navi2\">" to:@"</div>"] index:2]];
    return array;
}

- (NSArray*)parseSection:(NSString*)string index:(int)section {
    NSMutableArray* boards = [NSMutableArray array];
    NSScanner* scanner = [NSScanner scannerWithString:[string stringByRemovingHTMLComments]];
    while (!scanner.isAtEnd) {
        [scanner skip:@"href=\""];
        NSString* href;
        if (![scanner scanUpToString:@"\"" intoString:&href]) {
            break;
        }
        [scanner skip:@">"];
        if ([scanner scanString:@"<img" intoString:NULL]) {
            [scanner skip:@">"];
        }
        if ([scanner scanString:@"<font" intoString:NULL]) {
            [scanner skip:@">"];
        }
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
//        NSLog(@"%s: %@ %@", __func__, title, href);
        if ([href rangeOfString:@"board.php"].location != NSNotFound) {
            OCBoard* board = [[OCBoard alloc] init];
            board.URL = [NSURL URLWithString:href relativeToURL:[[self class] URL]];
            board.title = title;
            [boards addObject:board];
        } else {
            NSLog(@"%s: bad href=%@", __func__, href);
        }
    }
    return boards;
}

@end
