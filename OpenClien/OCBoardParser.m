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
#import "OCComment.h"

@implementation OCBoardParser
{
    OCBoard *_board;
    NSString *responseString; // fixme 제거
    int _page;
    NSString *_lastArticleId;
    NSURL *_nextSearchURL;
    GDataXMLDocument *_document;
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
    if ([_board isImage]) {
        return [self parseImage:data];
    } else {
        return [self parseNonImage:data];
    }
}

- (NSArray *)parseNonImage:(NSData *)data {
    NSError *error;
    _document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (_document) {
        GDataXMLNode *node = _document.rootElement[@"//div[@class='board_main']/table/form"][0];
        if (node) {
//            NSLog(@"%@", node.XMLString);
            BOOL isSearch = [[node[@"./input[@name='stx'][1]/@value"][0] stringValue] length];
            
            if (!isSearch) {
                GDataXMLNode *page = node[@"./input[@name='page']/@value"][0];
                int p = [page.stringValue intValue];
                if (p != _page + 1) {
                    _lastArticleId = nil;
                }
                _page = p;
            }
            
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
                if (!isSearch && _lastArticleId && [article.ID compare:_lastArticleId] != NSOrderedAscending) {
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
                        article.imageNameURL = [NSURL URLWithString:src relativeToURL:_board.URL];
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

            NSArray *next = _document.rootElement[@"//a[@class='cur_page']/following-sibling::a[1]"];
            if ([next count]) {
                NSString *href = [[next[0] attributeForName:@"href"] stringValue];
                _nextSearchURL = [NSURL URLWithString:href relativeToURL:_board.URL];
            }
            
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

- (NSArray *)parseImage:(NSData *)data {
    NSError *error;
    _document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (_document) {
        // fixme
        NSLog(@"%@", _document);
        GDataXMLNode *node = _document.rootElement[@"//div[@class='board_main']/table/form"][0];
        if (node) {
            //            NSLog(@"%@", node.XMLString);
            GDataXMLNode *page = node[@"./input[@name='page']/@value"][0];
            int p = [page.stringValue intValue];
            if (p != _page + 1) {
                _lastArticleId = nil;
            }
            _page = p;
            
            NSMutableArray* articles = [NSMutableArray array];
            int overlapCount = 0;
            
            NSArray *trs = node[@"./tbody/tr"];
            for (int i = 0; i < [trs count]; ++i) {
                GDataXMLElement *tr = trs[i];
                OCArticle *article = [[OCArticle alloc] init];

                NSArray *array = tr[@".//div[@class='view_title']//a"];
                if ([array count]) {
                    ++i; // NOTE
                    
                    GDataXMLElement *viewTitle = array[0];
                    NSString *href = [[viewTitle attributeForName:@"href"] stringValue];
                    article.ID = [[href componentsSeparatedByString:@"="] lastObject];
                    if (/*isLoadingMore && !_searchDisplayController.active &&*/ _lastArticleId && [article.ID compare:_lastArticleId] != NSOrderedAscending) {
                        ++overlapCount;
                        continue;
                    }
                    article.URL = [NSURL URLWithString:href relativeToURL:_board.URL];
                    
                    article.title = [viewTitle stringValue];
                    
                    [self parseContent:trs[i] ofImageArticle:article];
                } else {
                    array = tr[@".//div[@class='view_head']/span"];
                    article.title = [array[0] stringValue];
                    article.ID = [[array[1] attributeForName:@"wr_id"] stringValue];
                }
                
                GDataXMLElement *head = tr[@".//div[@class='view_head']"][0];
                GDataXMLNode *src = [head firstNodeForXPath:@".//@src" error:&error];
                if (src) {
                    article.imageNameURL = [NSURL URLWithString:src.stringValue relativeToURL:_board.URL];
                    NSLog(@"이미지네임 %@", article.imageNameURL);
                } else {
                    GDataXMLNode *user = [head firstNodeForXPath:@".//span[@class='member']" error:&error];
                    article.name = user.stringValue;
                    NSLog(@"user %@", article.name);
                }
                
                GDataXMLNode* info = [head firstNodeForXPath:@".//p[@class='post_info']" error:&error];
                NSScanner *scanner = [NSScanner scannerWithString:info.stringValue];
                NSString *date;
                int hit;
                int vote;
                [scanner scanUpToString:@" ," intoString:&date] &&
                [scanner scanString:@", Hit :" intoString:NULL] &&
                [scanner scanInt:&hit] &&
                [scanner scanString:@", Vote :" intoString:NULL] &&
                [scanner scanInt:&vote];
                NSLog(@"%@ h=%d v=%d", date, hit, vote);
                article.date = date;
                article.hit = hit;
                article.vote = vote;
                
                NSLog(@"%@", article);
                
                [articles addObject:article];
            }
            
            OCArticle* lastArticle = [articles lastObject];
            _lastArticleId = lastArticle.ID;
            
            return articles;
        }
    } else {
        // fixme 오류 보고
        NSLog(@"%@", error);
    }
    return nil;
    
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
        article.imageNameURL = [NSURL URLWithString:src relativeToURL:_board.URL];
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

- (void)parseContent:(GDataXMLElement *)content ofImageArticle:(OCArticle *)article
{
    // fixme
    GDataXMLElement *viewContent = content[@".//div[@class='view_content']"][0];

    NSArray *imgs = viewContent[@"./img"];
    NSMutableArray *images = [NSMutableArray array];
    for (GDataXMLElement *img in imgs) {
        NSURL *URL = [NSURL URLWithString:[[img attributeForName:@"src"] stringValue]];
        [images addObject:URL];
    }
    article.images = images;
    
    article.content = [viewContent[@"./span[@id='writeContents']"][0] stringValue];
    
    NSArray *replyHeads = viewContent[@".//div[contains(@class, 'reply_head')]"];
    NSArray *saveComments = viewContent[@".//textarea[contains(@id, 'save_comment_')]"];
    NSMutableArray *comments = [NSMutableArray array];
    int j = 0;
    for (int i = 0; i < [replyHeads count]; ++i) {
        OCComment *comment = [[OCComment alloc] init];
        GDataXMLElement *head = replyHeads[i];
        NSArray *li = head[@"./ul[@class='reply_info']/li"];
        if ([li count]) {
            comment.isNested = [li[0][@"./img[contains(@src, '/blet_re2.gif')]"] count];
            NSArray *array = li[0][@".//a"];
            if ([array count]) {
                GDataXMLElement *e = array[0];
                array = [[e attributeForName:@"onclick"].stringValue componentsSeparatedByString:@"'"];
                comment.memberId = array[1];
                comment.name = array[3];
                comment.home = array[7];
            }
            
            NSArray *img = li[0][@".//img[contains(@src, '/member/')]"];
            if ([img count]) {
                GDataXMLElement *e = img[0];
                comment.imageNameURL = [NSURL URLWithString:[e attributeForName:@"src"].stringValue relativeToURL:article.URL];
                //                        NSLog(@"이미지네임 %@", comment.imageNameURL);
            } else if (!comment.name) {
                GDataXMLNode *member = li[0][@".//span[@class='member']"][0];
                comment.name = member.stringValue;
                //                        NSLog(@"%@", member.stringValue);
            }

            NSString *date;
            NSScanner *scanner = [NSScanner scannerWithString:[li[1] stringValue]];
            [scanner scanString:@"(" intoString:NULL] &&
            [scanner scanUpToString:@")" intoString:&date];
            comment.date = date;
            
            array = head[@".//li[@class='ip']"];
            if ([array count]) {
                comment.IP = [array[0] stringValue];
            }
            
            comment.repliable = [head[@".//img[@alt='답변']"] count];
            comment.editable = [head[@".//img[@alt='수정']"] count];
            comment.deletable = [head[@".//img[alt='삭제']"] count];
            comment.reportable = [head[@".//img[alt='신고']"] count];
            
            comment.content = [saveComments[j] stringValue];
            comment.commentId = [[[saveComments[j] attributeForName:@"id"] stringValue] componentsSeparatedByString:@"_"][2];
            ++j;
        } else {
            comment.content = [head[@"./text()"][0] stringValue];
            // fixme 관리자가 삭제한 댓글은 bullet 이미지가 없음
            comment.isNested = [head[@"../../@style[contains(., '30px')]"] count];
            comment.commentId = [head[@"./span/@wr_id"][0] stringValue];
        }
        [comments addObject:comment];
    }
    article.comments = comments;
}

- (NSURL *)URLForNextPage
{
    return [NSURL URLWithString:[_board.URL.absoluteString stringByAppendingFormat:@"&page=%d", _page + 1]];
}

- (int)page
{
    return _page;
}

- (NSURLRequest *)requestForSearchString:(NSString *)string field:(OCSearchField)field {
    NSString* stx = [string.precomposedStringWithCanonicalMapping stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    static NSString* sfls[] = {@"wr_subject", @"wr_content", @"wr_subject||wr_content", @"mb_id,1", @"mb_id,0", @"wr_name,1", @"wr_name,0"};
    NSString* sfl = [sfls[field] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *URL = [NSURL URLWithString:[_board.URL.absoluteString stringByAppendingFormat:@"&sca=&sfl=%@&stx=%@", sfl, stx]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:_board.URL.absoluteString forHTTPHeaderField:@"Referer"];
    return request;
}

- (NSURLRequest *)requestForNextSearch {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_nextSearchURL];
    [request setValue:_board.URL.absoluteString forHTTPHeaderField:@"Referer"];
    return request;
}

- (BOOL)canSearch {
    return [_document.rootElement[@"//input[@id='stx']"] count];
}

@end
