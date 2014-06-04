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
@property (nonatomic, copy) NSString *title;

/**
 글 ID
 */
@property (nonatomic, copy) NSString *ID;

/**
 글 URL
 */
@property (nonatomic, strong) NSURL *URL;

/**
 글쓴이 닉네임
 */
@property (nonatomic, copy) NSString *name;

/**
 글쓴이 이미지네임 URL
 */
@property (copy, nonatomic) NSURL *imageNameURL;

/**
 댓글 개수
 */
@property (nonatomic, assign) int numberOfComments;

/**
 사진 게시판 글의 사진 URL
 */
@property (nonatomic, strong) NSArray *images;

/**
 작성일
 */
@property (nonatomic, copy) NSString *date;

/**
 조회수
 */
@property (nonatomic, assign) int hit;

/**
 추천수 (사진게시판)
 */
@property (nonatomic) int vote;

/**
 공지사항 여부
 */
@property (nonatomic, assign) BOOL isNotice;

/**
 카테고리
 */
@property (nonatomic, copy) NSString *category;

/**
 내용 (사진게시판)
 */
@property (copy, nonatomic) NSString *content;

/**
 (대)댓글 (사진게시판)
 */
@property (strong, nonatomic) NSArray *comments;

@end
