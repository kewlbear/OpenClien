//
//  OCLoginParser.m
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

#import "OCLoginParser.h"
#import "GDataXMLNode+OpenClien.h"

@implementation OCLoginParser

+ (NSURL *)URL
{
    return [NSURL URLWithString:@"http://www.clien.net/cs2/bbs/login_check.php"];
}

+ (NSDictionary *)parametersForId:(NSString *)loginId password:(NSString *)password URL:(NSURL *)url
{
    return @{@"mb_id": loginId,
             @"mb_password": password,
             @"url": [url path]};
}

- (BOOL)parse:(NSData *)data error:(NSError *__autoreleasing *)error
{
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithHTMLData:data encoding:NSUTF8StringEncoding error:error];
    if (document) {
        // 성공: <html><head><script language="JavaScript"><![CDATA[ location.replace('http://www.clien.net/cs2/bbs/board.php?nowlogin=1'); ]]></script></head></html>
        // 실패: <html><head><meta http-equiv="content-type" content="text/html; charset=utf-8"/><script language="javascript"><![CDATA[alert('회원아이디나 패스워드가 공백이면 안됩니다.');history.go(-1);]]></script></head></html>
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

@end
