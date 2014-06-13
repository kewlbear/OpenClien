//
//  OCCommentParser.m
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

#import "OCCommentParser.h"
#import "OCArticle.h"
#import "GDataXMLNode+OpenClien.h"
#import "OCComment.h"

@implementation OCCommentParser

+ (NSURL *)URL
{
    return [NSURL URLWithString:@"http://www.clien.net/cs2/bbs/write_comment_update.php"];
}

- (NSDictionary *)parametersForArticle:(OCArticle *)article content:(NSString *)content
{
    NSString *w = @"c"; // 댓글
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSArray* array = [article.URL.query componentsSeparatedByString:@"&"];
    for (NSString* parameter in array) {
        NSArray* nameValue = [parameter componentsSeparatedByString:@"="];
        //        NSLog(@"%@", nameValue);
        parameters[nameValue[0]] = nameValue[1];
    }
    parameters[@"wr_content"] = content;
    parameters[@"w"] = w;
    return parameters;
}

- (BOOL)parse:(NSData *)data error:(NSError **)error
{
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithHTMLData:data encoding:NSUTF8StringEncoding error:error];
    if (document) {
        NSArray *array = [[document.rootElement stringValue] componentsSeparatedByString:@"'"];
        if ([array[0] rangeOfString:@"alert"].length) {
            NSLog(@"%@", array[1]);
            *error = [NSError errorWithDomain:@"OpenClienErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: array[1]}];
            return NO;
        }
        return YES;
    } else {
        NSLog(@"%@", *error);
    }
    return NO;
}

- (void)prepareWithContent:(NSString *)content comment:(OCComment *)comment block:(void (^)(NSURL *, NSDictionary *))block {
    NSMutableDictionary *parameters = [[self parametersForArticle:comment.article content:content] mutableCopy];
    parameters[@"comment_id"] = comment.branch ? comment.branch.commentId : comment.commentId;
    block([[self class] URL], parameters);
}

@end
