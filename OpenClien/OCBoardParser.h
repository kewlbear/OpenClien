//
//  OCBoardParser.h
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
 검색 기준 필드
 */
typedef enum : NSUInteger {
    OCSearchFieldTitle,             /// 제목
    OCSearchFieldContent,           /// 내용
    OCSearchFieldTitleAndContent,   /// 제목+내용
    OCSearchFieldMemberId,          /// 회원아이디
    OCSearchFieldMemberIdOfComment, /// 회원아이디(코)
    OCSearchFieldName,              /// 이름
    OCSearchFieldNameOfComment      /// 이름(코)
} OCSearchField;

@class OCBoard;

/**
 게시판 목록 파서입니다.
 */
@interface OCBoardParser : NSObject

@property (nonatomic, readonly) int page;

/**
 글 쓰기 URL
 */
@property (readonly, nonatomic) NSURL *writeURL;

/**
 주어진 게시판을 위해 초기화한 파서를 반환합니다.
 
 @param board 게시판
 
 @return 주어진 게시판을 위해 초기화한 파서
 */
- (id)initWithBoard:(OCBoard *)board;

/**
 HTML 데이터에 해당하는 OCArticle 배열을 반환한다.
 
 @param data HTML 데이터
 
 @return HTML 데이터에 해당하는 OCArticle 배열
 */
- (NSArray *)parse:(NSData *)data;

/**
 다음 페이지를 위한 URL 요청을 반환한다.
 
 @return 다음 페이지를 위한 URL 요청
 */
- (NSURLRequest *)requestForNextPage;

/**
 이 게시판의 주어진 검색어와 필드에 해당하는 검색 URL 요청을 반환한다.
 
 @param string 검색어
 @param field 검색 기준 필드
 
 @return 주어진 검색어와 필드에 해당하는 검색 URL 요청
 */
- (NSURLRequest *)requestForSearchString:(NSString *)string field:(OCSearchField)field;

/**
 검색이 가능한 상태인지 반환한다.
 
 @return 검색가능 여부
 */
- (BOOL)canSearch;

/**
 카테고리 배열을 반환한다.
 
 @return 카테고리 배열
 */
- (NSArray *)categories;

/**
 주어진 카테고리의 글 목록을 가져올 수 있는 URL 요청을 반환한다.
 
 @param 카테고리
 
 @return 주어진 카테고리의 글 목록을 가져올 수 있는 URL 요청
 */
- (NSURLRequest *)requestForCategory:(NSString *)category;

/**
 다음 검색 URL 요청을 반환한다.
 
 @return 다음 검색 URL 요청
 */
- (NSURLRequest *)requestForNextSearch;

@end
