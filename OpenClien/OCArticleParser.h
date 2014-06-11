//
//  OCArticleParser.h
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

@class OCArticle;

/**
 게시판 글 페이지 파서입니다.
 */
@interface OCArticleParser : NSObject

/**
 글 내용 HTML
 */
@property (nonatomic, readonly) NSString *content;

/**
 댓글 목록
 */
@property (nonatomic, readonly) NSArray *comments;

/**
 로그인 여부
 */
@property (nonatomic, readonly) BOOL loggedIn;

/**
 스크랩 가능
 */
@property (nonatomic, readonly) BOOL canScrap;

/**
 댓글 가능
 */
@property (readonly, nonatomic) BOOL canComment;

/**
 글 제목
 */
@property (readonly, nonatomic) NSString *title;

/**
 글쓴이 닉네임
 */
@property (readonly, nonatomic) NSString *name;

/**
 글쓴이 이미지네임
 */
@property (readonly, nonatomic) NSURL *imageNameURL;

/**
 링크 NSURL
 */
@property (readonly, nonatomic) NSArray *links;

/**
 글 HTML data를 분석하여 content와 comments을 추출한다.
 */
- (void)parse:(NSData *)data article:(OCArticle *)article;

@end
