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
 클리앙 관련 카테고리
 */
@interface NSURL (OpenClien)

/**
 클리앙 게시판 글 URL인지 확인한다.
 */
- (BOOL)isClienURL;

/**
 URL에 해당하는 OCArticle을 반환한다.
 */
- (OCArticle *)article;

/**
 수신자(receiver)에 해당하는 OCBoard을 반환한다.
 
 @return 수신자에 해당하는 OCBoard
 */
- (OCBoard *)board;

@end
