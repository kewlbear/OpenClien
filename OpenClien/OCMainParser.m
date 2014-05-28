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
#import "OCBoard.h"
#import "GDataXMLNode+OpenClien.h"

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
    NSError *error;
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (document) {
        return @[[self parseGroup:document.rootElement[@".//div[@id='snb_navi1']//a[contains(@href, 'board.php')]"]],
                 [self parseGroup:document.rootElement[@".//div[@id='snb_navi2']//a[contains(@href, 'board.php')]"]]
                 ];
    } else {
        NSLog(@"%@", error);
        // fixme report error
    }
    return nil;
}

- (NSArray *)parseGroup:(NSArray *)array
{
    NSMutableArray *boards = [NSMutableArray array];
    for (GDataXMLElement *a in array) {
        [boards addObject:[self parseBoard:a]];
    }
    return boards;
}

- (OCBoard *)parseBoard:(GDataXMLElement *)a
{
    OCBoard *board = [[OCBoard alloc] init];
    board.URL = [NSURL URLWithString:[[a attributeForName:@"href"] stringValue] relativeToURL:[[self class] URL]];
    board.title = [a stringValue];
    return board;
}

@end
