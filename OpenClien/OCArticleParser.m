//
//  OCArticleParser.m
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

#import "OCArticleParser.h"
#import <iconv.h>
#import "NSString+SubstringFromTo.h"
#import <GDataXMLNode+OpenClien.h>
#import "OCArticle.h"
#import "OCComment.h"

@implementation OCArticleParser
{
    NSString *_response;
    NSString *_content;
    NSArray *_comments;
    NSString *_username;
    NSURL *_imageNameURL;
    NSString *_title;
    NSString *_date;
    int _hit;
    int _vote;
    GDataXMLDocument *_document;
}

- (void)parse:(NSData *)data article:(OCArticle *)article
{
    NSError *error;
    _document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (_document) {
        GDataXMLNode *node = [_document.rootElement firstNodeForXPath:@"//div[@class='board_main']" error:&error];
        if (node) {
            GDataXMLNode *head = [node firstNodeForXPath:@".//div[@class='view_head']" error:&error];
            GDataXMLNode *src = [head firstNodeForXPath:@".//@src" error:&error];
            if (src) {
                _imageNameURL = [NSURL URLWithString:src.stringValue relativeToURL:article.URL];
                NSLog(@"이미지네임 %@", _imageNameURL);
            } else {
                GDataXMLNode *user = [head firstNodeForXPath:@".//span[@class='member']" error:&error];
                _username = user.stringValue;
                NSLog(@"user %@", _username);
            }
            GDataXMLNode* info = [head firstNodeForXPath:@".//p[@class='post_info']" error:&error];
            NSScanner *scanner = [NSScanner scannerWithString:info.stringValue];
            NSString *date;
            [scanner scanUpToString:@" ," intoString:&date] &&
            [scanner scanString:@", Hit :" intoString:NULL] &&
            [scanner scanInt:&_hit] &&
            [scanner scanString:@", Vote :" intoString:NULL] &&
            [scanner scanInt:&_vote];
            _date = date;
            NSLog(@"%@ h=%d v=%d", _date, _hit, _vote);
            GDataXMLNode *title = [node firstNodeForXPath:@".//div[@class='view_title']//span/text()" error:&error];
            _title = title.stringValue;
            NSLog(@"%@", _title);
            GDataXMLNode *content = [node firstNodeForXPath:@".//div[@class='view_content']" error:&error];
            
            NSArray *links = [content nodesForXPath:@".//a[contains(@href, 'link.php')]" error:&error];
            if (links) {
                NSLog(@"links: %@", links);
                for (GDataXMLNode *link in links) {
                    GDataXMLNode *href = [link firstNodeForXPath:@".//@href" error:&error];
                    GDataXMLNode *text = [link firstNodeForXPath:@".//text()" error:&error];
                    NSScanner *scanner = [NSScanner scannerWithString:text.stringValue];
                    NSString *direct;
                    int count = -1;
                    [scanner scanUpToString:@" " intoString:&direct] &&
                    [scanner scanString:@"(" intoString:NULL] &&
                    [scanner scanInt:&count];
                    NSURL *URL = [NSURL URLWithString:href.stringValue relativeToURL:article.URL];
                    NSLog(@"link %d %@ %@", count, URL, direct);
                    // fixme 링크 정보 제공
                }
            }
            
            content = [content firstNodeForXPath:@".//div[@class='resContents']" error:&error];
            
            NSArray *flashs = content[@".//embed"];
            if ([flashs count]) {
                // fixme
                for (GDataXMLElement *flash in flashs) {
                    GDataXMLElement *parent = flash[@".."][0];
                    if ([parent.name isEqualToString:@"object"]) {
                        NSLog(@"object %@", [parent XMLString]);
                    } else {
                        NSLog(@"embed %@", [flash XMLString]);
                    }
                }
            }
            
            // img 태그에서 width 속성 제거
            NSArray *imgs = content[@".//img[@width]"];
            for (GDataXMLElement *img in imgs) {
                NSLog(@"width %@", [img XMLString]);
                xmlUnsetProp(img.XMLNode, (const xmlChar *) "width");
                NSLog(@"after %@", [img XMLString]);
            }
            
            // style="... width: xxx ..." 에서 width: xxx 제거
            NSArray *array = content[@".//*[contains(@style, 'width')]"];
            for (GDataXMLElement *e in array) {
                NSArray *styles = [[[e attributeForName:@"style"] stringValue] componentsSeparatedByString:@";"];
                __block NSMutableArray *keep = [NSMutableArray array];
                __block int n = 0;
                [styles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSError *error;
                    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@".?width[: ]" options:0 error:&error];
                    NSRange range = [re rangeOfFirstMatchInString:obj options:0 range:NSMakeRange(0, [obj length])];
                    if (range.length) {
                        unichar firstCharacter = [obj characterAtIndex:range.location];
                        if (firstCharacter == 'w' || firstCharacter == ' ') {
                            ++n;
                            return;
                        }
                    }
                    [keep addObject:obj];
                }];
                if (n) {
                    NSLog(@"style %@ %@", [e name], [[e attributeForName:@"style"] stringValue]);
                    xmlUnsetProp(e.XMLNode, (const xmlChar *) "style");
                    if ([keep count]) {
                        [e addAttribute:[GDataXMLNode attributeWithName:@"style" stringValue:[keep componentsJoinedByString:@";"]]];
                    }
                    NSLog(@"after %@ %@", [e name], [[e attributeForName:@"style"] stringValue]);
                }
            }
            
            _content = [@[head.XMLString, title.stringValue, content.XMLString] componentsJoinedByString:@""];
            // fixme 위에서 제대로 처리
            if ([flashs count]) {
                _content = [_content stringByAppendingString:@"<script src=\"http://iamghost.kr/d/iOSBookmarklets/video.js\"></script>"];
            }
            
            NSArray *replyHeads = node[@".//div[contains(@class, 'reply_head')]"];
            NSArray *saveComments = node[@".//textarea[contains(@id, 'save_comment_')]"];
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
                        GDataXMLNode *member = [li[0] firstNodeForXPath:@".//span[@class='member']" error:&error];
                        comment.name = member.stringValue;
//                        NSLog(@"%@", member.stringValue);
                    }
                    
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
            _comments = comments;
            return;
        } else {
            node = [_document.rootElement firstNodeForXPath:@"//script[last()]" error:&error]; // fixme
//            NSLog(@"%@", node.stringValue);
            NSArray *array = [node.stringValue componentsSeparatedByString:@"'"];
            // fixme report error
            NSLog(@"%@", [array[1] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]);
        }
//        NSLog(@"%@", node ? node.XMLString : error);
    } else {
        // fixme report error
        NSLog(@"%@", error);
    }
}

- (NSString *)content
{
    return _content;
}

- (NSArray *)comments
{
    return _comments;
}

- (BOOL)loggedIn
{
    return NO; // fixme
}

- (BOOL)canScrap
{
    return [_document.rootElement[@"//a[contains(@href,'win_scrap')][1]"] count];
}

- (BOOL)canComment
{
    return [_document.rootElement[@".//div[@class='reply_write']"] count];
}

@end
