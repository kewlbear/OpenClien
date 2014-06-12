//
//  OCScrapParser.h
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

#import <Foundation/Foundation.h>

/**
 스크랩하기 페이지 파서

 URL은 OCArticleParser 클래스의 scrapURL 속성에서 가져온다.
 */
@interface OCScrapParser : NSObject

/**
 스크랩할 때 입력했던 메모
 */
@property (readonly, nonatomic) NSArray *memos;

/**
 주어진 URL로 파서를 초기화한다.
 
 @param URL 베이스 URL

 @return 주어진 URL로 초기화된 파서
 */
- (instancetype)initWithURL:(NSURL *)URL;

/**
 스크랩 페이지의 HTML을 분석한다.
 
 @param data 스크랩 페이지 HTML 데이터
 */
- (void)parse:(NSData *)data;

/**
 주어진 메모를 포함하여 서버에 보낼 요청을 만드는 데 필요한 정보를 취합하여 주어진 블록을 호출한다.
 
    [scrapParser prepareSubmitWithMemo:@"메모" block:^(NSURL *URL, NSDictionary *parameters) {
        // URL과 parameters을 사용하여 서버에 POST 요청 전송
        // 서버가 보낸 응답 데이터를 parseSubmitResponse: 에 전달
    }];
 
 @param memo 스크랩에 사용할 메모
 @param block 서버에 보낼 요청을 만드는 데 필요한 정보를 넘겨받을 블록
 
 @see -parseSubmitResponse:
 */
- (void)prepareSubmitWithMemo:(NSString *)memo block:(void (^)(NSURL *URL, NSDictionary *parameters))block;

/**
 스크랩 결과를 분석한다.
 */
- (void)parseSubmitResponse:(NSData *)data;

@end
