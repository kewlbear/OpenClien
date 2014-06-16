//
//  NSURL+OpenClien.h
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
@class OCBoard;

/**
 이 카테고리는 NSURL 클래스에 OpenClien 관련 메소드를 추가한다.
 */
@interface NSURL (OpenClien)

/**
 수신자의 게시판 글 URL 여부를 반환한다.
 
 @return 수신자가 게시판 글 URL이면 YES, 아니면 NO를 반환한다.
 */
- (BOOL)isClienURL;

/**
 수신자에 해당하는 OCArticle을 반환한다.
 
 @return 수신자에 해당하는 OCArticle
 */
- (OCArticle *)article;

/**
 수신자에 해당하는 OCBoard을 반환한다.
 
 @return 수신자에 해당하는 OCBoard
 */
- (OCBoard *)board;

@end
