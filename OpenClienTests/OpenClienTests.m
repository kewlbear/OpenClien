//
//  OpenClienTests.m
//  OpenClienTests
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

#import <XCTest/XCTest.h>
#import "OpenClien.h"

@interface OpenClienTests : XCTestCase

@end

@implementation OpenClienTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParsingArticleWithFileAndLink
{
    OCArticleParser *parser = [[OCArticleParser alloc] init];
    NSURL *URL = [NSURL URLWithString:@"http://www.clien.net/cs2/bbs/board.php?bo_table=pds&wr_id=123454"];
    NSData *data = [NSData dataWithContentsOfURL:URL];
    OCArticle *article = [URL article];
    [parser parse:data article:article];
    XCTAssertGreaterThan([parser.files count], 0);
    XCTAssertGreaterThan([parser.links count], 0);
}

@end
