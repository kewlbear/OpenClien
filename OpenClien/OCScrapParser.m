//
//  OCScrapParser.m
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

#import "OCScrapParser.h"
#import "GDataXMLNode+OpenClien.h"

@implementation OCScrapParser {
    GDataXMLDocument *_document;
    NSURL *_URL;
}

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _URL = URL;
    }
    return self;
}

- (void)parse:(NSData *)data {
    // fixme
    NSError *error;
    _document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (_document) {
        // fixme
    } else {
        // fixme
        NSLog(@"%@", error);
    }
}

- (NSArray *)memos {
    NSMutableArray *memos = [NSMutableArray array];
    NSArray *values = _document.rootElement[@"//select[@name='ms_memo']/option[@value]/@value"];
    for (GDataXMLNode *value in values) {
        [memos addObject:[value stringValue]];
    }
    return memos;
}

- (void)prepareSubmitWithMemo:(NSString *)memo block:(void (^)(NSURL *, NSDictionary *))block {
    NSArray *forms = _document.rootElement[@"//form[@name='f_scrap_popin'][1]"];
    GDataXMLElement *form = forms[0];
    NSString *action = [[form attributeForName:@"action"] stringValue];
    NSURL *URL = [NSURL URLWithString:action relativeToURL:_URL];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"wr_content"] = memo;
    NSArray *inputs = form[@".//input[@type='hidden']"];
    for (GDataXMLElement *input in inputs) {
        parameters[[[input attributeForName:@"name"] stringValue]] = [[input attributeForName:@"value"] stringValue];
    }
    
    block(URL, parameters);
}

- (void)parseSubmitResponse:(NSData *)data {
    NSError *error;
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (document) {
        NSArray *scripts = document.rootElement[@"//script[contains(text(), '이 글을 스크랩 하였습니다.')][1]"];
        if ([scripts count]) {
            NSLog(@"%@", scripts[0]);
        } else {
            NSLog(@"%@", document.rootElement);
        }
    } else {
        // fixme report
        NSLog(@"%@", error);
    }
}

@end
