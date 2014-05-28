//
//  OCLoginParser.h
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
 로그인 페이지 파서
 */
@interface OCLoginParser : NSObject

/**
 로그인 페이지 URL
 */
+ (NSURL *)URL;

/**
 POST 파라미터
 */
+ (NSDictionary *)parametersForId:(NSString *)loginId password:(NSString *)password URL:(NSURL *)url;

/**
 로그인 결과 분석
 */
- (BOOL)parse:(NSData *)data error:(NSError **)error;

@end
