//
//  OCLogoutParser.h
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
 로그아웃 페이지 파서
 */
@interface OCLogoutParser : NSObject

/**
 로그아웃 URL을 반환한다.
 
 @return 로그아웃 URL
 */
+ (NSURL *)URL;

/**
 로그아웃 결과를 분석한다.
 
 @param 로그아웃 결과 HTML
 */
- (void)parse:(NSData *)data;

@end
