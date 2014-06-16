//
//  OCComment.h
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
 OCComment는 게시판 댓글의 모델 클래스입니다.
 */
@interface OCComment : NSObject

/**
 댓글 쓴 사람 닉네임
 */
@property (nonatomic, copy) NSString *name;

/**
 댓글 쓴 사람 이미지네임 URL
 */
@property (nonatomic, strong) NSURL *imageNameURL;

/**
 댓글 내용
 */
@property (nonatomic, copy) NSString *content;

/**
 댓글 쓴 시각
 */
@property (nonatomic, copy) NSString *date;

/**
 대댓글 여부
 */
@property (nonatomic, assign) BOOL isNested;

/**
 IP 주소
 */
@property (copy, nonatomic) NSString *IP;

/**
 회원 ID
 */
@property (copy, nonatomic) NSString *memberId;

/**
 홈페이지
 */
@property (copy, nonatomic) NSString *home;

/**
 댓글 ID
 */
@property (copy, nonatomic) NSString *commentId;

/**
 대댓글 가능
 */
@property (nonatomic) BOOL repliable;

/**
 신고 가능
 */
@property (nonatomic) BOOL reportable;

/**
 수정 가능
 */
@property (nonatomic) BOOL editable;

/**
 삭제 가능
 */
@property (nonatomic) BOOL deletable;

/**
 이 댓글이 달린 글
 */
@property (strong, nonatomic) OCArticle *article;

/**
 대댓글일 경우 원래 댓글
 */
@property (strong, nonatomic) OCComment *branch;

@end
