//
//  OCArticle.h
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
 OCArticle은 클리앙 게시판 글의 모델 클래스입니다.
 */
@interface OCArticle : NSObject

/**
 제목
 */
@property (nonatomic, copy) NSString *title; // fixme readonly

/**
 글 ID
 */
@property (nonatomic, copy) NSString *ID; // fixme readonly, rename?

/**
 글 URL
 */
@property (nonatomic, strong) NSURL *URL; // fixme readonly

/**
 글쓴이 닉네임
 */
@property (nonatomic, copy) NSString *name; // fixme readonly

/**
 댓글 개수
 */
@property (nonatomic, assign) int numberOfComments; // fixme readonly

/**
 사진 게시판 글의 사진 URL
 */
@property (nonatomic, strong) NSURL *imageURL; // fixme readonly

/**
 작성일
 */
@property (nonatomic, copy) NSString *date;

/**
 조회수
 */
@property (nonatomic, assign) int hit;

/**
 공지사항 여부
 */
@property (nonatomic, assign) BOOL isNotice;

/**
 카테고리
 */
@property (nonatomic, copy) NSString *category;

@end
