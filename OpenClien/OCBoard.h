//
//  OCBoard.h
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
 OCBoard는 클리앙 게시판의 모델 클래스입니다.
 */
@interface OCBoard : NSObject <NSCoding>

/**
 게시판 이름
 */
@property (nonatomic, copy) NSString *title; // fixme readonly

/**
 게시판의 첫 페이지 글 목록을 가져올 때 사용하는 URL
 */
@property (nonatomic, strong) NSURL *URL; // fixme readonly

/**
 사진 게시판 여부
 */
@property (nonatomic, readonly, getter = isImage) BOOL image;

@end
