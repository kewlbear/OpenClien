//
//  OCFile.h
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
 첨부 파일
 */
@interface OCFile : NSObject

/**
 다운로드 URL
 */
@property (strong, nonatomic) NSURL *URL;

/**
 파일명
 */
@property (copy, nonatomic) NSString *name;

/**
 크기
 */
@property (copy, nonatomic) NSString *size;

/**
 다운로드 수
 */
@property (nonatomic) int downloadCount;

/**
 업로드 일시
 */
@property (copy, nonatomic) NSString *date;

@end
