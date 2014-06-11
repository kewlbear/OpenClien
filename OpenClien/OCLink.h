//
//  OCLink.h
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
 글 작성시 입력한 링크
 */
@interface OCLink : NSObject

/**
 URL
 */
@property (strong, nonatomic) NSURL *URL;

/**
 사용자에게 보여줄 텍스트
 */
@property (copy, nonatomic) NSString *text;

/**
 링크 클릭 수
 */
@property (nonatomic) int hitCount;

@end
