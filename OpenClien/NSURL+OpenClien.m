//
//  NSURL+OpenClien.m
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

#import "NSURL+OpenClien.h"
#import "OCArticle.h"

@implementation NSURL (OpenClien)

- (BOOL)isClienURL
{
    // fixme 리다이렉션 처리
    return [@[@"www.clien.net", @"clien.net", @"m.clien.net", @"clien.career.co.kr"] containsObject:self.host] &&
    [self.lastPathComponent hasPrefix:@"board"] &&
    [self.query rangeOfString:@"wr_id="].location != NSNotFound;
}

- (OCArticle *)article
{
    OCArticle *article = [[OCArticle alloc] init];
    NSString* url = [self.absoluteString stringByReplacingOccurrencesOfString:@"m.clien.net/cs3/board" withString:@"www.clien.net/cs2/bbs/board.php"];
    article.URL = [NSURL URLWithString:url];
    return article;
}

@end
