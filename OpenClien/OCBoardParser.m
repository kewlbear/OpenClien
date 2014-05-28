//
//  OCBoardParser.m
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

#import "OCBoardParser.h"
#import "OCBoard.h"
#import "NSString+SubstringFromTo.h"
#import "OCArticle.h"
#import "NSScanner+Skip.h"
#import "GTMNSString+HTML.h"
#import "GDataXMLNode+OpenClien.h"

@implementation OCBoardParser
{
    OCBoard *_board;
    NSString *responseString;
    int _page;
    NSString *_lastArticleId;
}

- (id)initWithBoard:(OCBoard *)board
{
    self = [super init];
    if (self) {
        _board = board;
        _page = 1;
    }
    return self;
}

- (NSArray *)parse:(NSData *)data
{
//    if (isLoadingMore) {
//        ++page;
//    }
    NSArray *array;
    if ([_board isImage]) {
        responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        array = [self parseImage];
    } else {
        array = [self parseNonImage:data];
    }
    //        responseString = nil;
    
//    shouldLoadMore = YES;
    return array;
}

- (NSArray *)parseNonImage:(NSData *)data {
    NSError *error;
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (document) {
        GDataXMLNode *node = document.rootElement[@"//div[@class='board_main']/table/form"][0];
        if (node) {
//            NSLog(@"%@", node.XMLString);
            GDataXMLNode *page = node[@"./input[@name='page']/@value"][0];
            int p = [page.stringValue intValue];
            if (p != _page + 1) {
                _lastArticleId = nil;
            }
            _page = p;
            
            NSMutableArray* array = [NSMutableArray array];
            int overlapCount = 0;
            
            NSString *xpath = @"./tbody/tr";
            if (_page > 1) {
                xpath = [xpath stringByAppendingString:@"[not(@class='post_notice')]"];
            }
            NSArray *trs = node[xpath];
            for (GDataXMLElement *tr in trs) {
                NSArray *tds = tr[@"./td"];
                // 체험단 사용기 광고
                if ([tds count] < 5) {
                    continue;
                }
                
                OCArticle *article = [[OCArticle alloc] init];
                
                article.isNotice = [[tr attributeForName:@"class"].stringValue isEqualToString:@"post_notice"];
                
                article.ID = [tds[0] stringValue];
                if (/*isLoadingMore && !_searchDisplayController.active &&*/ _lastArticleId && [article.ID compare:_lastArticleId] != NSOrderedAscending) {
                    ++overlapCount;
                    continue;
                }

                NSArray *category = tr[@"./td[@class='post_category']"];
                if ([category count]) {
                    article.category = [category[0] stringValue];
                }
                
                NSArray *title = tr[@"./td[@class='post_subject']/a"];
                if ([title count]) {
                    NSString *href = [title[0] attributeForName:@"href"].stringValue;
                    article.URL = [NSURL URLWithString:href relativeToURL:_board.URL];

                    NSArray *comments = tr[@".//td[@class='post_subject']/span[1]"];
                    if ([comments count]) {
                        NSScanner *scanner = [NSScanner scannerWithString:[comments[0] stringValue]];
                        [scanner scanString:@"[" intoString:NULL];
                        int count;
                        [scanner scanInt:&count];
                        article.numberOfComments = count;
                    }
                    
                    GDataXMLNode *name = [tr[@".//td[@class='post_name' or @class='post_name_h']"][0] childAtIndex:0];
                    if ([name.name isEqualToString:@"a"]) { // 로그인했을 때
                        // fixme
                        name = [name childAtIndex:0];
                    }
                    if ([name.name isEqualToString:@"img"]) { // 이미지네임
                        NSString* src = [(GDataXMLElement *) name attributeForName:@"src"].stringValue;
                        article.imageURL = [NSURL URLWithString:src relativeToURL:_board.URL];
                    } else {
                        article.name = name.stringValue;
                    }
                    
                    GDataXMLNode *date = [tds[tds.count - 2] childAtIndex:0];
                    if (date.kind == GDataXMLElementKind) {
                        article.date = [(GDataXMLElement *) date attributeForName:@"title"].stringValue;
                    } else {
                        article.date = date.stringValue;
                    }
                    
                    article.hit = [[tds[tds.count - 1] stringValue] intValue];
                } else {
                    title = tr[@"./td[@class='post_subject']/span"];
                }
                article.title = [title[0] stringValue];
                
//                NSLog(@"%@", article);
                
                [array addObject:article];
            }
            
            OCArticle* lastArticle = [array lastObject];
            _lastArticleId = lastArticle.ID;

            return array;
        }
    } else {
        NSLog(@"%@", error);
    }
    return nil;
    
    NSScanner* scanner = [NSScanner scannerWithString:[responseString substringFrom:@"<form name=\"fboardlist\"" to:@"</tbody>"]];
    //    NSLog(@"%s: %@", __func__, scanner.string);
    NSMutableArray* array = [NSMutableArray array];
    int overlapCount = 0;
    while (!scanner.isAtEnd) {
        OCArticle* article = [[OCArticle alloc] init];
        [scanner skip:@"<tr"];
        // 공지사항
        BOOL isNotice = [scanner scanString:@"class=\"post_notice\"" intoString:NULL];
        [scanner skip:@"<td"];
        // 체험단 사용기 광고
        if (![scanner scanString:@">" intoString:NULL]) {
            continue;
        }
        NSString* articleId;
        if (!isNotice && ![scanner scanUpToString:@"<" intoString:&articleId]) {
            break;
        }
//        if (isLoadingMore && !_searchDisplayController.active && [articleId compare:lastArticleId] != NSOrderedAscending) {
//            ++overlapCount;
//            continue;
//        }
        article.ID = articleId;
        [scanner skip:@"class=\"post_subject\">"];
        NSString* title;
        if ([scanner scanString:@"<span " intoString:NULL]) {
            [scanner skip:@"'>"];
            [scanner scanUpToString:@"</span>" intoString:&title];
        } else {
            [scanner skip:@"href='"];
            NSString* href;
            [scanner scanUpToString:@"'" intoString:&href];
            article.URL = [NSURL URLWithString:href relativeToURL:_board.URL];
            [scanner skip:@">"];
            [scanner scanUpToString:@"</a>" intoString:&title];
        }
//        if (self.searchDisplayController.active) {
//            // fixme use attributed string
//            title = [title stringByReplacingOccurrencesOfString:@"<span class='search_text'>" withString:@""];
//            title = [title stringByReplacingOccurrencesOfString:@"</span>" withString:@""];
//        }
        article.title = title.gtm_stringByUnescapingFromHTML;
        [scanner skip:@"</a>"];
        if ([scanner scanString:@"<span>[" intoString:NULL]) {
            int numberOfComments;
            [scanner scanInt:&numberOfComments];
            article.numberOfComments = numberOfComments;
        }
        [scanner skip:@"<td class=\"post_name"];
        [scanner skip:@">"];
        if ([scanner scanString:@"<a " intoString:NULL]) {
            [scanner skip:@">"];
        }
        NSString* name;
        if ([scanner scanString:@"<span class='member'>" intoString:NULL]) {
            [scanner scanUpToString:@"</span>" intoString:&name];
        } else {
            [scanner skip:@"src='"];
            [scanner scanUpToString:@"'" intoString:&name];
            name = [[NSURL URLWithString:name relativeToURL:_board.URL] absoluteString];
        }
        article.name = name;
        //        [scanner skip:@"<span title=\""];
        //        NSString* timestamp;
        //        [scanner scanUpToString:@"\">" intoString:&timestamp];
        //        article.timestamp = timestamp;
        //        [scanner skip:@"<td>"];
        //        int numberOfHits;
        //        [scanner scanInt:&numberOfHits];
        //        article.numberOfHits = numberOfHits;
        [array addObject:article];
        //        NSLog(@"%s: %@ %@", __func__, articleId, title);
    }
    NSLog(@"%d overlaps", overlapCount);
//    if (self.searchDisplayController.active) {
//        if (isLoadingMore) {
//            [_searchResults addObjectsFromArray:array];
//        } else {
//            _searchResults = array;
//        }
//        [self.searchDisplayController.searchResultsTableView reloadData];
//    } else {
//        if (isLoadingMore) {
//            [articles addObjectsFromArray:array];
//        } else {
//            articles = array;
//        }
//        Article* lastArticle = [array lastObject];
//        lastArticleId = lastArticle.ID;
//        [self.tableView reloadData];
//    }
//    [self setRefreshButton];
    return array;
}

- (NSArray *)parseImage {
    NSScanner* scanner = [NSScanner scannerWithString:[responseString substringFrom:@"<form name=\"fboardlist\"" to:@"</tbody>"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    NSMutableArray* array = [NSMutableArray array];
    while (!scanner.isAtEnd) {
        OCArticle* article = [[OCArticle alloc] init];
        [scanner skip:@"<p class=\"user_info"];
        [scanner skip:@">"];
        if ([scanner scanString:@"<a href=\"javascript:;\"" intoString:NULL]) {
            [scanner skip:@">"];
        }
        NSString* name;
        if ([scanner scanString:@"<span class='member'>" intoString:NULL]) {
            [scanner scanUpToString:@"</span>" intoString:&name];
        } else {
            [scanner skip:@"src="];
            NSString* quote;
            if ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote]) {
                [scanner scanUpToString:quote intoString:&name];
                name = [[NSURL URLWithString:name relativeToURL:_board.URL] absoluteString];
            }
        }
        if (!name) {
            break;
        }
        NSLog(@"%s: name=%@", __func__, name);
        article.name = name;
        [scanner skip:@"<p class=\"post_info\">"];
        NSString* postInfo;
        [scanner scanUpToString:@"</p>" intoString:&postInfo];
        NSLog(@"%s: post_info=%@", __func__, postInfo);
        [scanner skip:@"<h4>"];
        [scanner skip:@"href="];
        NSString* quote;
        [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote];
        NSLog(@"%s: quote=%@", __func__, quote);
        NSString* href;
        [scanner scanUpToString:quote intoString:&href];
        NSLog(@"%s: href=%@", __func__, href);
        article.URL = [NSURL URLWithString:href relativeToURL:_board.URL];
        [scanner skip:@">"];
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        NSLog(@"%s: title=%@", __func__, title);
        article.title = title.gtm_stringByUnescapingFromHTML;
        [scanner skip:@"src="];
        [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote];
        NSString* src;
        [scanner scanUpToString:quote intoString:&src];
        NSLog(@"%s: src=%@", __func__, src);
        article.imageURL = [NSURL URLWithString:src relativeToURL:_board.URL];
        [scanner skip:@"span id=\"writeContents\""];
        [scanner skip:@">"];
        NSString* content;
        [scanner scanUpToString:@"</span>" intoString:&content];
        NSLog(@"%s: content=%@", __func__, content);
        [array addObject:article];
        //        NSLog(@"%s: %@ %@", __func__, href, title);
    }
//    articles = array;
//    if (!isLoadingMore) {
//        self.tableView.rowHeight = ceilf(self.tableView.bounds.size.height / array.count);
//    }
//    [self.tableView reloadData];
//    [self setRefreshButton];
    return array;
}

- (NSURL *)URLForNextPage
{
    return [NSURL URLWithString:[_board.URL.absoluteString stringByAppendingFormat:@"&page=%d", _page + 1]];
}

- (int)page
{
    return _page;
}

@end
