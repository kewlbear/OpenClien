//
//  OCMainParser.h
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
 메인 페이지 HTML을 분석하여 게시판/소모임 정보를 가져옵니다.
 */
@interface OCMainParser : NSObject

/**
 메인 페이지 URL을 반환합니다.
 
 @return 메인 페이지 URL
 */
+ (NSURL*)URL;

/**
 메인 페이지 HTML에서 가져온 게시판/소모임 목록을 반환한다.
 
 @param data 메인 페이지 HTML
 
 @return 메인 페이지 HTML에서 가져온 게시판/소모임 목록. 색인 0에는 게시판, 1에는 소모임 OCBoard 배열이 들어간다.
 
 @see +URL
 */
- (NSArray*)parse:(NSData*)data;

@end
